using System.IO;
using System.Text.RegularExpressions;

var controllersDir = @"c:\D\FYP\Medi-AI_F-B-main\Medi_AI_Backend_railway\Backend-APIs\Controllers";
var files = Directory.GetFiles(controllersDir, "*.cs");

foreach (var file in files) {
    var content = File.ReadAllText(file);
    var original = content;

    content = Regex.Replace(content, @"\[Authorize\(Roles\s*=\s*""Admin,admin""\)\]", "[Authorize(Roles = Backend_APIs.Constants.UserRoles.Admin)]");
    content = Regex.Replace(content, @"\[Authorize\(Roles\s*=\s*""Doctor,Admin""\)\]", "[Authorize(Roles = Backend_APIs.Constants.UserRoles.Doctor + \",\" + Backend_APIs.Constants.UserRoles.Admin)]");
    content = Regex.Replace(content, @"\[Authorize\(Roles\s*=\s*""Admin""\)\]", "[Authorize(Roles = Backend_APIs.Constants.UserRoles.Admin)]");
    content = Regex.Replace(content, @"\[Authorize\(Roles\s*=\s*""Doctor""\)\]", "[Authorize(Roles = Backend_APIs.Constants.UserRoles.Doctor)]");
    content = Regex.Replace(content, @"\[Authorize\(Roles\s*=\s*""Doctor,Faculty,Admin""\)\]", "[Authorize(Roles = Backend_APIs.Constants.UserRoles.Doctor + \",\" + Backend_APIs.Constants.UserRoles.Faculty + \",\" + Backend_APIs.Constants.UserRoles.Admin)]");
    
    // Feedback Controller
    content = Regex.Replace(content, @"u\.Role\s*==\s*""Admin""\s*\|\|\s*u\.Role\s*==\s*""admin""", "u.Role == Backend_APIs.Constants.UserRoles.Admin");
    
    // Doctors Controller
    content = Regex.Replace(content, @"u\.Role\s*==\s*""Doctor""\s*\|\|\s*u\.Role\s*==\s*""doctor""", "u.Role == Backend_APIs.Constants.UserRoles.Doctor");

    if (content != original) {
        File.WriteAllText(file, content);
    }
}
