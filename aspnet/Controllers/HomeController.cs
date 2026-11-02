using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using ServiceHub_IT.Interfaces;
using ServiceHub_IT.Models;
using ServiceHub_IT.Services;

namespace ServiceHub_IT.Controllers;

[Authorize]
public class HomeController : Controller
{
    private readonly DashboardService _dashboardService;
    private readonly ISupabaseService _supabaseService;

    public HomeController(DashboardService dashboardService, ISupabaseService supabaseService)
    {
        _dashboardService = dashboardService;
        _supabaseService = supabaseService;
    }

    public IActionResult Index() => View();

    public async Task<IActionResult> Dashboard(CancellationToken cancellationToken)
    {
        var accessToken = User.FindFirst("supabase_access_token")?.Value ?? string.Empty;
        var metrics = await _dashboardService.GetMetricsAsync(accessToken, cancellationToken);
        return View(metrics);
    }

    public IActionResult Privacy() => View();

    public async Task<IActionResult> Profile(CancellationToken cancellationToken)
    {
        var profileClaim = User.FindFirst("profile_id")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var accessToken = User.FindFirst("supabase_access_token")?.Value ?? string.Empty;
        Profile? profile = null;

        if (Guid.TryParse(profileClaim, out var profileId))
        {
            profile = await _supabaseService.GetProfileByIdAsync(profileId, accessToken, cancellationToken);
        }

        profile ??= new Profile
        {
            Id = Guid.TryParse(profileClaim, out var fallbackId) ? fallbackId : Guid.Empty,
            FullName = User.FindFirst("full_name")?.Value ?? User.Identity?.Name ?? string.Empty,
            Email = User.FindFirst(ClaimTypes.Email)?.Value ?? User.FindFirst("email")?.Value ?? string.Empty,
            Role = User.FindFirst(ClaimTypes.Role)?.Value ?? "Client"
        };

        return View(profile);
    }

    [AllowAnonymous]
    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error() => View();
}
