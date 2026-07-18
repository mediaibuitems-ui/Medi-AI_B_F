using Backend_APIs.Models;
using Backend_APIs.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.FileProviders;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;
using System.Threading.RateLimiting;

namespace Backend_APIs
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);


            // Add MySQL DbContext
            var connectionString = BuildMySqlConnectionString(builder.Configuration);
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new InvalidOperationException("ConnectionStrings:DefaultConnection is not configured.");
            }

            builder.Services.AddDbContext<MediaidbContext>(options =>
                options.UseMySql(connectionString, ServerVersion.Parse("8.0.36-mysql")));

            // Add Services
            builder.Services.AddScoped<IEmailService, EmailService>();
            builder.Services.AddScoped<IAuthService, AuthService>();
            builder.Services.AddScoped<IUserService, UserService>();

            builder.Services.AddHttpClient();

            builder.Services.AddScoped<INotificationPushService, NotificationPushService>();
            
            // Register Background Services
            builder.Services.AddHostedService<TokenCleanupService>();

            // Configure ASP.NET Core Identity with custom BCrypt hasher for existing passwords
            builder.Services.AddScoped<Microsoft.AspNetCore.Identity.IPasswordHasher<User>, BCryptPasswordHasher>();
            builder.Services.AddIdentity<User, Microsoft.AspNetCore.Identity.IdentityRole<int>>(options =>
            {
                options.Password.RequireDigit = true;
                options.Password.RequiredLength = 8;
                options.Password.RequireNonAlphanumeric = false;
                options.Password.RequireUppercase = false;
                options.Password.RequireLowercase = false;
                options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
                options.Lockout.MaxFailedAccessAttempts = 5;
            })
            .AddEntityFrameworkStores<MediaidbContext>()
            .AddDefaultTokenProviders();

            // Configure JWT Authentication
            var jwtSettings = builder.Configuration.GetSection("Jwt");
            var jwtKey = builder.Configuration["Jwt:Key"] ?? Environment.GetEnvironmentVariable("JWT_KEY");
            if (string.IsNullOrWhiteSpace(jwtKey))
            {
                throw new InvalidOperationException("Jwt:Key is not configured. Set Jwt:Key in configuration or the JWT_KEY environment variable.");
            }

            var key = Encoding.UTF8.GetBytes(jwtKey);

            builder.Services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = jwtSettings["Issuer"],
                    ValidAudience = jwtSettings["Audience"],
                    IssuerSigningKey = new SymmetricSecurityKey(key)
                };
            });

            builder.Services.AddRateLimiter(options =>
            {
                options.AddFixedWindowLimiter("AuthLimiter", opt =>
                {
                    opt.PermitLimit = 5;
                    opt.Window = TimeSpan.FromMinutes(1);
                    opt.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
                    opt.QueueLimit = 2;
                });
                
                options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
            });

            builder.Services.AddControllers();
            builder.Services.AddMemoryCache();

            builder.Services.Configure<ApiBehaviorOptions>(options =>
            {
                options.InvalidModelStateResponseFactory = context =>
                {
                    var errors = context.ModelState
                        .Where(x => x.Value?.Errors.Count > 0)
                        .ToDictionary(
                            x => x.Key,
                            x => x.Value!.Errors.Select(e => e.ErrorMessage).ToArray());

                    return new BadRequestObjectResult(new DTOs.ApiResponse<object>
                    {
                        Success = false,
                        Message = "Invalid request data",
                        Data = null,
                        Errors = errors
                    });
                };
            });

            // Configure Swagger with JWT support
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen(options =>
            {
                options.SwaggerDoc("v1", new OpenApiInfo
                {
                    Title = "MediAI Backend API",
                    Version = "v1",
                    Description = "Healthcare Management System API"
                });

                // Add JWT Authentication to Swagger
                options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                {
                    Name = "Authorization",
                    Type = SecuritySchemeType.Http,
                    Scheme = "Bearer",
                    BearerFormat = "JWT",
                    In = ParameterLocation.Header,
                    Description = "Enter 'Bearer' followed by a space and your JWT token"
                });

                options.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference
                            {
                                Type = ReferenceType.SecurityScheme,
                                Id = "Bearer"
                            }
                        },
                        Array.Empty<string>()
                    }
                });
            });

            // Add CORS - read allowed origins from config or env in production
            var isDev = builder.Environment.IsDevelopment();
            var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>();
            if ((allowedOrigins == null || allowedOrigins.Length == 0) && !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("CORS_ALLOWED_ORIGINS")))
            {
                allowedOrigins = Environment.GetEnvironmentVariable("CORS_ALLOWED_ORIGINS")!.Split(';', System.StringSplitOptions.RemoveEmptyEntries);
            }

            builder.Services.AddCors(options =>
            {
                options.AddPolicy("DefaultCors", policy =>
                {
                    if (isDev)
                    {
                        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
                    }
                    else
                    {
                        if (allowedOrigins != null && allowedOrigins.Length > 0)
                        {
                            policy.WithOrigins(allowedOrigins)
                                  .AllowAnyHeader()
                                  .AllowAnyMethod()
                                  .AllowCredentials();
                        }
                        else
                        {
                            // Fallback: restrict to no origins if not configured to force deploy fail-safe
                            policy.DisallowCredentials();
                        }
                    }
                });
            });

            var app = builder.Build();

            // Use a global exception middleware to ensure consistent ApiResponse payloads
            app.UseMiddleware<Middleware.GlobalExceptionMiddleware>();
            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI(options =>
                {
                    options.SwaggerEndpoint("/swagger/v1/swagger.json", "MediAI API v1");
                    options.RoutePrefix = "swagger";
                });
            }



            //app.UseHttpsRedirection();

            // Enable serving static files (for profile photos)
            app.UseStaticFiles();

            app.UseCors("DefaultCors");

            app.UseRateLimiter(); // Add rate limiter here

            app.UseAuthentication();

            // JWT Revocation Middleware
            app.Use(async (context, next) =>
            {
                var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Split(" ").Last();
                if (!string.IsNullOrEmpty(token))
                {
                    var cache = context.RequestServices.GetRequiredService<Microsoft.Extensions.Caching.Memory.IMemoryCache>();
                    var dbContext = context.RequestServices.GetRequiredService<MediaidbContext>();
                    
                    var hashBytes = System.Security.Cryptography.SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(token));
                    var tokenHash = Convert.ToHexString(hashBytes).ToLowerInvariant();

                    if (cache.TryGetValue($"Blacklist_{tokenHash}", out _))
                    {
                        context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                        context.Response.ContentType = "application/json";
                        await context.Response.WriteAsync("{\"success\":false,\"message\":\"Token is invalid or revoked\",\"data\":null}");
                        return;
                    }
                    
                    // Fallback to DB check
                    var isRevoked = await dbContext.RevokedTokens.AnyAsync(r => r.TokenHash == tokenHash && r.ExpiresAt > DateTime.UtcNow);
                    if (isRevoked)
                    {
                        var cacheOptions = new Microsoft.Extensions.Caching.Memory.MemoryCacheEntryOptions
                        {
                            AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(24)
                        };
                        cache.Set($"Blacklist_{tokenHash}", true, cacheOptions);
                        
                        context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                        context.Response.ContentType = "application/json";
                        await context.Response.WriteAsync("{\"success\":false,\"message\":\"Token is invalid or revoked\",\"data\":null}");
                        return;
                    }
                }
                await next();
            });

            app.UseAuthorization();

            app.MapControllers();
            app.MapGet("/", () => Results.Ok(new
            {
                status = "Healthy",
                message = "Medi-AI Backend is running perfectly."
            }));

            // --- SAFE DATABASE MIGRATION BLOCK ---
            using (var scope = app.Services.CreateScope())
            {
                var services = scope.ServiceProvider;
                try
                {
                    var context = services.GetRequiredService<MediaidbContext>();
                    context.Database.Migrate(); // This is likely where the crash happens
                    
                    // Preload unexpired revoked tokens into cache
                    var cache = services.GetRequiredService<Microsoft.Extensions.Caching.Memory.IMemoryCache>();
                    var unexpiredTokens = context.RevokedTokens.Where(t => t.ExpiresAt > DateTime.UtcNow).ToList();
                    foreach (var token in unexpiredTokens)
                    {
                        var cacheOptions = new Microsoft.Extensions.Caching.Memory.MemoryCacheEntryOptions
                        {
                            AbsoluteExpiration = token.ExpiresAt
                        };
                        cache.Set($"Blacklist_{token.TokenHash}", true, cacheOptions);
                    }
                }
                catch (Exception ex)
                {
                    // Log it AND throw it so we can see the real error
                    var logger = services.GetRequiredService<ILogger<Program>>();
                    logger.LogError(ex, "DATABASE CRASHED!");
                    throw; // Add this line to see the actual error in the output window
                }
                // -------------------------------------
            }
            app.Run();
        }


        private static string BuildMySqlConnectionString(IConfiguration configuration)
        {
            var mysqlUrl = Environment.GetEnvironmentVariable("MYSQL_URL")
                ?? Environment.GetEnvironmentVariable("DATABASE_URL");

            if (!string.IsNullOrWhiteSpace(mysqlUrl))
            {
                var uri = new Uri(mysqlUrl);
                var userInfo = uri.UserInfo.Split(':', 2);
                var user = userInfo.Length > 0 ? Uri.UnescapeDataString(userInfo[0]) : string.Empty;
                var password = userInfo.Length > 1 ? Uri.UnescapeDataString(userInfo[1]) : string.Empty;
                var database = uri.AbsolutePath.TrimStart('/');
                var port = uri.Port > 0 ? uri.Port : 3306;

                return $"Server={uri.Host};Port={port};Database={database};User ID={user};Password={password};";
            }

            var host = Environment.GetEnvironmentVariable("MYSQLHOST");
            var portValue = Environment.GetEnvironmentVariable("MYSQLPORT");
            var databaseName = Environment.GetEnvironmentVariable("MYSQLDATABASE");
            var userName = Environment.GetEnvironmentVariable("MYSQLUSER");
            var passwordValue = Environment.GetEnvironmentVariable("MYSQLPASSWORD");

            if (!string.IsNullOrWhiteSpace(host)
                && !string.IsNullOrWhiteSpace(databaseName)
                && !string.IsNullOrWhiteSpace(userName))
            {
                var port = string.IsNullOrWhiteSpace(portValue) ? "3306" : portValue;
                return $"Server={host};Port={port};Database={databaseName};User ID={userName};Password={passwordValue};";
            }

            return configuration.GetConnectionString("DefaultConnection") ?? string.Empty;
        }
    }
}
