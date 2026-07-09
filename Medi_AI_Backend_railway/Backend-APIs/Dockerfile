# Cache bust: 1
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy csproj and restore as distinct layers
COPY ["Backend-APIs.csproj", "./"]
RUN dotnet restore "Backend-APIs.csproj"

# Copy everything else and build
COPY . .
RUN dotnet publish "Backend-APIs.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Backend-APIs.dll"]
