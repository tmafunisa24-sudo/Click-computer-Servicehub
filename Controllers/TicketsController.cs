using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ServiceHub_IT.Interfaces;
using ServiceHub_IT.Models;
using ServiceHub_IT.Services;

namespace ServiceHub_IT.Controllers;

[Authorize]
public class TicketsController : Controller
{
    private readonly TicketService _ticketService;
    private readonly ISupabaseService _supabaseService;
    private readonly NotificationService _notificationService;
    private readonly ILogger<TicketsController> _logger;

    public TicketsController(TicketService ticketService, ISupabaseService supabaseService, NotificationService notificationService, ILogger<TicketsController> logger)
    {
        _ticketService = ticketService;
        _supabaseService = supabaseService;
        _notificationService = notificationService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> Index(CancellationToken cancellationToken)
    {
        var email = User.Identity?.Name ?? User.FindFirst("email")?.Value ?? string.Empty;
        IReadOnlyList<Ticket> tickets;

        if (User.IsInRole("Admin"))
        {
            tickets = await _ticketService.GetTicketsAsync(cancellationToken: cancellationToken);
        }
        else if (User.IsInRole("Technician"))
        {
            tickets = await _ticketService.GetTicketsAsync(assignedTechnician: email, cancellationToken: cancellationToken);
        }
        else
        {
            var profileId = GetCurrentProfileId();
            tickets = profileId == Guid.Empty
                ? Array.Empty<Ticket>()
                : await _ticketService.GetTicketsAsync(employeeId: profileId, cancellationToken: cancellationToken);
        }

        var technicians = (await _supabaseService.GetTechniciansAsync(cancellationToken)).OrderBy(p => p.FullName).ThenBy(p => p.Email).ToList();
        ViewBag.Technicians = technicians;
        return View(tickets);
    }

    [HttpGet]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> Create(CancellationToken cancellationToken)
    {
        try
        {
            await PopulateCatalogAsync(cancellationToken);
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "TicketsController.Create could not load the service catalog because the Supabase session expired.");
            return RedirectToAction("Login", "Auth", new { returnUrl = Request.Path.ToString() });
        }

        return View(new CreateTicketViewModel());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> Create(CreateTicketViewModel model, CancellationToken cancellationToken)
    {
        _logger.LogInformation("TicketsController.Create POST entered.");

        if (string.IsNullOrWhiteSpace(model.Title) && !string.IsNullOrWhiteSpace(model.ProblemType))
        {
            model.Title = $"{model.DeviceType} repair: {model.ProblemType}";
        }

        if (string.IsNullOrWhiteSpace(model.Category))
        {
            model.Category = model.ProblemCategory;
        }

        ModelState.Remove(nameof(model.Title));
        ModelState.Remove(nameof(model.Category));

        List<ServiceCatalogItem> catalog;
        try
        {
            catalog = (await _supabaseService.GetActiveServiceCatalogAsync(GetSupabaseAccessToken(), cancellationToken)).ToList();
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "TicketsController.Create could not load the service catalog because the Supabase session expired.");
            return RedirectToAction("Login", "Auth", new { returnUrl = Request.Path.ToString() });
        }
        var selectedService = catalog.FirstOrDefault(service => service.Id == model.ServiceCatalogId
            && string.Equals(service.DeviceType, model.DeviceType, StringComparison.OrdinalIgnoreCase)
            && string.Equals(service.ProblemCategory, model.ProblemCategory, StringComparison.OrdinalIgnoreCase)
            && string.Equals(service.ProblemType, model.ProblemType, StringComparison.OrdinalIgnoreCase));
        if (selectedService is null)
        {
            ModelState.AddModelError(nameof(model.ServiceCatalogId), "Select a valid active repair problem.");
        }

        if (!ModelState.IsValid)
        {
            ViewBag.ServiceCatalog = catalog;
            _logger.LogWarning("TicketsController.Create ModelState invalid. Errors: {Errors}", string.Join(" | ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage)));
            return View(model);
        }

        _logger.LogInformation("TicketsController.Create ModelState valid.");

        var requester = User.FindFirst(ClaimTypes.Email)?.Value
            ?? User.FindFirst("email")?.Value
            ?? User.Identity?.Name
            ?? string.Empty;
        var clientProfileId = GetCurrentProfileId();
        if (clientProfileId == Guid.Empty)
        {
            ModelState.AddModelError(string.Empty, "Your Client profile could not be resolved.");
            ViewBag.ServiceCatalog = catalog;
            return View(model);
        }
        _logger.LogInformation(
            "TicketsController.Create received repair request: DeviceType={DeviceType}, ProblemCategory={ProblemCategory}, ProblemType={ProblemType}, ServiceCatalogId={ServiceCatalogId}, EmployeeId={EmployeeId}, Title={Title}, Description={Description}, Priority={Priority}",
            model.DeviceType, model.ProblemCategory, model.ProblemType, model.ServiceCatalogId, clientProfileId, model.Title, model.Description, model.Priority);
        var requesterProfile = await _supabaseService.GetProfileByEmailAsync(requester, cancellationToken);
        var requesterName = !string.IsNullOrWhiteSpace(requesterProfile?.FullName) ? requesterProfile.FullName : requester;
        var ticket = new Ticket
        {
            employee_id = clientProfileId,
            device_type = model.DeviceType,
            problem_category = model.ProblemCategory,
            problem_type = model.ProblemType,
            service_catalog_id = model.ServiceCatalogId,
            title = model.Title,
            description = model.Description,
            requester = requester,
            priority = model.Priority,
            category = model.Category,
            payment_status = "Pending",
            comments = string.Empty,
            assigned_technician = null,
            status = "Open",
            created_at = DateTime.UtcNow,
            updated_at = DateTime.UtcNow
        };

        _logger.LogInformation(
            "TicketsController.Create building ticket payload. Requester={Requester}, Title={Title}, Category={Category}, Priority={Priority}, Status={Status}, CreatedAt={CreatedAt}",
            ticket.requester,
            ticket.title,
            ticket.category,
            ticket.priority,
            ticket.status,
            ticket.created_at);

        try
        {
            var created = await _ticketService.CreateTicketAsync(ticket, GetSupabaseAccessToken(), cancellationToken);
            if (!created)
            {
                TempData.Remove("Success");
                TempData["Error"] = "Unable to create the ticket right now.";
                _logger.LogError("TicketsController.Create CreateTicketAsync returned false for ticket title {Title}.", ticket.title);
                return View(model);
            }

            var imageFiles = model.Images.Where(file => file is not null).ToList();
            if (model.Screenshot is not null)
            {
                imageFiles.Add(model.Screenshot);
            }
            if (imageFiles.Count > 0)
            {
                try
                {
                    var uploadedAttachments = await _ticketService.UploadTicketImagesAsync(ticket.id!, imageFiles, clientProfileId, GetSupabaseAccessToken(), cancellationToken);
                    var primaryAttachment = uploadedAttachments.FirstOrDefault();
                    if (primaryAttachment is not null)
                    {
                        ticket.screenshot_url = primaryAttachment.FileUrl;
                    }
                    else
                    {
                        throw new HttpRequestException("The uploaded screenshot record could not be found.");
                    }
                }
                catch (Exception ex) when (ex is InvalidDataException or HttpRequestException or InvalidOperationException)
                {
                    _logger.LogError(ex, "Ticket image upload failed after ticket {TicketId} was created.", ticket.id);
                    TempData["Error"] = "The ticket was created, but one or more images could not be uploaded. Please try again.";
                }
            }

            var ticketLink = Url.Action("Details", "Tickets", new { id = ticket.id }) ?? $"/Tickets/Details?id={ticket.id}";
            var adminProfiles = (await _supabaseService.GetProfilesByRoleAsync("Admin", cancellationToken))
                .Where(profile => profile is not null && profile.Id != Guid.Empty)
                .GroupBy(profile => profile.Id)
                .Select(group => group.First())
                .ToList();

            if (adminProfiles.Count == 0)
            {
                _logger.LogWarning("TicketsController.Create no admin profiles found for ticket {TicketId}.", ticket.id);
            }
            else
            {
                foreach (var adminProfile in adminProfiles)
                {
                    try
                    {
                        _logger.LogInformation("Creating new ticket notification for admin {AdminUserId} for ticket {TicketId}", adminProfile.Id, ticket.id);
                        await _notificationService.CreateNotificationAsync(
                            adminProfile.Id,
                            "New Support Ticket",
                            $"A new support ticket '{ticket.title}' has been created by {requesterName}.",
                            "new_ticket",
                            ticketLink,
                            cancellationToken);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Failed to create new ticket notification for admin {AdminUserId} for ticket {TicketId}", adminProfile.Id, ticket.id);
                    }
                }
            }

            if (TempData["Error"] is not null)
            {
                return RedirectToAction(nameof(Payment), new { id = ticket.id });
            }

            TempData.Remove("Error");
            TempData["Success"] = "Ticket created successfully.";
            _logger.LogInformation("TicketsController.Create ticket inserted successfully and redirecting to My Tickets.");
            return RedirectToAction(nameof(Payment), new { id = ticket.id });
        }
        catch (Exception ex)
        {
            TempData.Remove("Success");
            TempData["Error"] = "Unable to create the ticket right now.";
            _logger.LogError(ex, "TicketsController.Create exception while creating ticket for title {Title}.", ticket.title);
            return View(model);
        }
    }

    [HttpGet]
    public async Task<IActionResult> Details(string id, CancellationToken cancellationToken)
    {
        var ticket = await _ticketService.GetTicketByIdAsync(id, cancellationToken);
        if (ticket is null)
        {
            return NotFound();
        }

        if (User.IsInRole("Client") && ticket.employee_id != GetCurrentProfileId())
        {
            return Forbid();
        }

        var technicians = (await _supabaseService.GetTechniciansAsync(cancellationToken)).OrderBy(p => p.FullName).ThenBy(p => p.Email).ToList();
        ViewBag.Technicians = technicians;
        ViewBag.Attachments = await _ticketService.GetTicketAttachmentsAsync(id, GetSupabaseAccessToken(), cancellationToken);
        if (string.IsNullOrWhiteSpace(ticket.screenshot_url) && string.IsNullOrWhiteSpace(ticket.image_url)
            && ViewBag.Attachments is IReadOnlyList<TicketAttachment> attachments && attachments.Count > 0)
        {
            ticket.screenshot_url = attachments[0].FileUrl;
        }
        return View(ticket);
    }

    [HttpGet]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> Payment(string id, CancellationToken cancellationToken)
    {
        var ticket = await _ticketService.GetTicketByIdAsync(id, cancellationToken);
        if (ticket is null)
        {
            return NotFound();
        }

        if (ticket.employee_id != GetCurrentProfileId())
        {
            return Forbid();
        }

        return View(ticket);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> Payment(string id, PaymentMethodViewModel model, CancellationToken cancellationToken)
    {
        var ticket = await _ticketService.GetTicketByIdAsync(id, cancellationToken);
        if (ticket is null)
        {
            return NotFound();
        }

        if (ticket.employee_id != GetCurrentProfileId())
        {
            return Forbid();
        }

        var paymentMethod = model.PaymentMethod?.Trim();
        if (!string.Equals(paymentMethod, "Card", StringComparison.OrdinalIgnoreCase)
            && !string.Equals(paymentMethod, "Cash", StringComparison.OrdinalIgnoreCase))
        {
            ModelState.AddModelError(nameof(model.PaymentMethod), "Select Card or Cash.");
            return View(ticket);
        }

        ticket.payment_method = string.Equals(paymentMethod, "Card", StringComparison.OrdinalIgnoreCase) ? "Card" : "Cash";
        ticket.payment_status = "Pending";
        ticket.updated_at = DateTime.UtcNow;

        if (!await _ticketService.UpdateTicketAsync(ticket, cancellationToken))
        {
            ModelState.AddModelError(string.Empty, "Unable to save the payment method. Please try again.");
            return View(ticket);
        }

        TempData["PaymentSuccess"] = $"Payment method saved: {ticket.payment_method}";
        return RedirectToAction(nameof(Details), new { id = ticket.id });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ConfirmPayment(string id, CancellationToken cancellationToken)
    {
        var ticket = await _ticketService.GetTicketByIdAsync(id, cancellationToken);
        if (ticket is null)
        {
            return NotFound();
        }

        var hasPaymentMethod = string.Equals(ticket.payment_method, "Card", StringComparison.OrdinalIgnoreCase)
            || string.Equals(ticket.payment_method, "Cash", StringComparison.OrdinalIgnoreCase);
        if (!hasPaymentMethod || !string.Equals(ticket.payment_status, "Pending", StringComparison.OrdinalIgnoreCase))
        {
            TempData["Error"] = string.Equals(ticket.payment_status, "Paid", StringComparison.OrdinalIgnoreCase)
                ? "Payment is already confirmed."
                : "Only a pending Card or Cash payment can be confirmed.";
            return RedirectToAction(nameof(Details), new { id });
        }

        if (!await _ticketService.ConfirmPaymentAsync(id, cancellationToken))
        {
            TempData["Error"] = "Unable to confirm the payment.";
            return RedirectToAction(nameof(Details), new { id });
        }

        TempData["PaymentSuccess"] = "Payment confirmed successfully.";
        return RedirectToAction(nameof(Details), new { id });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> AssignTechnician(string id, string assignedTechnician, DateTime? dueDate, CancellationToken cancellationToken)
    {
        var ticket = await _ticketService.GetTicketByIdAsync(id, cancellationToken);
        if (ticket is null)
        {
            return NotFound();
        }

        if (User.IsInRole("Client") && ticket.employee_id != GetCurrentProfileId())
        {
            return Forbid();
        }

        ticket.assigned_technician = assignedTechnician;
        ticket.status = "Assigned";
        ticket.due_date = dueDate;
        ticket.updated_at = DateTime.UtcNow;

        var updated = await _ticketService.UpdateTicketAsync(ticket, cancellationToken);
        if (!updated)
        {
            TempData["Error"] = "Unable to assign the technician.";
            return RedirectToAction(nameof(Index));
        }

        var ticketLink = Url.Action("Details", "Tickets", new { id = ticket.id }) ?? $"/Tickets/Details?id={ticket.id}";
        var technicianProfile = await ResolveProfileAsync(assignedTechnician, cancellationToken);
        if (technicianProfile is null || technicianProfile.Id == Guid.Empty)
        {
            _logger.LogWarning("TicketsController.AssignTechnician could not resolve technician profile for assignment value {AssignedTechnician} for ticket {TicketId}.", assignedTechnician, ticket.id);
        }
        else
        {
            _logger.LogInformation("Creating assignment notification for technician {TechnicianUserId} for ticket {TicketId}", technicianProfile.Id, ticket.id);
            await _notificationService.CreateNotificationAsync(
                technicianProfile.Id,
                "New Ticket Assigned",
                $"Ticket '{ticket.title}' has been assigned to you.",
                "ticket_assigned",
                ticketLink,
                cancellationToken);
        }

        TempData["Success"] = "Technician assigned successfully.";
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = "Admin,Technician")]
    public async Task<IActionResult> UpdateStatus(string id, UpdateTicketStatusViewModel model, CancellationToken cancellationToken)
    {
        var ticket = await _ticketService.GetTicketByIdAsync(id, cancellationToken);
        if (ticket is null)
        {
            return NotFound();
        }

        var normalizedStatus = NormalizeStatus(model.Status);
        if (!CanTransition(ticket.status, normalizedStatus))
        {
            TempData["Error"] = "Status updates must follow the required workflow order.";
            return RedirectToAction(nameof(Details), new { id });
        }

        var actor = User.Identity?.Name ?? User.FindFirst("email")?.Value ?? string.Empty;
        ticket.status = normalizedStatus;
        ticket.updated_at = DateTime.UtcNow;
        if (model.DueDate.HasValue)
        {
            ticket.due_date = model.DueDate.Value;
        }

        if (!string.IsNullOrWhiteSpace(model.AssignedTechnician))
        {
            ticket.assigned_technician = model.AssignedTechnician;
        }

        if (!string.IsNullOrWhiteSpace(model.Comment))
        {
            ticket.comments = string.IsNullOrWhiteSpace(ticket.comments)
                ? $"{actor}: {model.Comment}"
                : $"{ticket.comments}\n{actor}: {model.Comment}";
        }

        var updated = await _ticketService.UpdateTicketAsync(ticket, cancellationToken);
        if (!updated)
        {
            TempData["Error"] = "Unable to update the ticket.";
            return RedirectToAction(nameof(Details), new { id });
        }

        var ticketLink = Url.Action("Details", "Tickets", new { id = ticket.id }) ?? $"/Tickets/Details?id={ticket.id}";
        var statusMessage = $"Ticket '{ticket.title}' is now {ticket.status}.";
        await _notificationService.CreateNotificationForEmailAsync(
            ticket.requester,
            "Ticket status updated",
            statusMessage,
            "ticket_status",
            ticketLink,
            cancellationToken);

        if (!string.IsNullOrWhiteSpace(ticket.assigned_technician) && !string.Equals(ticket.assigned_technician, ticket.requester, StringComparison.OrdinalIgnoreCase))
        {
            await _notificationService.CreateNotificationForEmailAsync(
                ticket.assigned_technician,
                "Ticket status updated",
                statusMessage,
                "ticket_status",
                ticketLink,
                cancellationToken);
        }

        if (!string.IsNullOrWhiteSpace(model.Comment))
        {
            var commenter = User.Identity?.Name ?? User.FindFirst("email")?.Value ?? "Someone";
            var commentRecipient = !string.Equals(ticket.requester, commenter, StringComparison.OrdinalIgnoreCase)
                ? ticket.requester
                : ticket.assigned_technician;

            if (!string.IsNullOrWhiteSpace(commentRecipient))
            {
                await _notificationService.CreateNotificationForEmailAsync(
                    commentRecipient,
                    "New comment on your ticket",
                    $"{commenter} added a comment to ticket '{ticket.title}'.",
                    "ticket_comment",
                    ticketLink,
                    cancellationToken);
            }
        }

        TempData["Success"] = "Ticket status updated successfully.";
        return RedirectToAction(nameof(Details), new { id });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> ConfirmClose(string id, CancellationToken cancellationToken)
    {
        var ticket = await _ticketService.GetTicketByIdAsync(id, cancellationToken);
        if (ticket is null)
        {
            return NotFound();
        }

        if (ticket.employee_id != GetCurrentProfileId())
        {
            return Forbid();
        }

        if (!string.Equals(ticket.status, "Resolved", StringComparison.OrdinalIgnoreCase))
        {
            TempData["Error"] = "The ticket must be marked resolved before it can be closed.";
            return RedirectToAction(nameof(Details), new { id });
        }

        ticket.status = "Closed";
        ticket.updated_at = DateTime.UtcNow;
        var updated = await _ticketService.UpdateTicketAsync(ticket, cancellationToken);
        if (!updated)
        {
            TempData["Error"] = "Unable to close the ticket.";
            return RedirectToAction(nameof(Details), new { id });
        }

        var ticketLink = Url.Action("Details", "Tickets", new { id = ticket.id }) ?? $"/Tickets/Details?id={ticket.id}";
        await _notificationService.CreateNotificationForEmailAsync(
            ticket.requester,
            "Ticket closed",
            $"Your ticket '{ticket.title}' has been closed.",
            "ticket_resolved",
            ticketLink,
            cancellationToken);

        TempData["Success"] = "Ticket closed successfully.";
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(string id, CancellationToken cancellationToken)
    {
        var deleted = await _ticketService.DeleteTicketAsync(id, cancellationToken);
        if (!deleted)
        {
            TempData["Error"] = "Unable to delete the ticket.";
            return RedirectToAction(nameof(Index));
        }

        TempData["Success"] = "Ticket deleted successfully.";
        return RedirectToAction(nameof(Index));
    }

    private async Task<Profile?> ResolveProfileAsync(string? identifier, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(identifier))
        {
            return null;
        }

        if (Guid.TryParse(identifier, out var profileId))
        {
            return await _supabaseService.GetProfileByIdAsync(profileId, cancellationToken);
        }

        return await _supabaseService.GetProfileByEmailAsync(identifier, cancellationToken);
    }

    private Guid GetCurrentProfileId()
    {
        var value = User.FindFirst("profile_id")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(value, out var profileId) ? profileId : Guid.Empty;
    }

    private async Task PopulateCatalogAsync(CancellationToken cancellationToken)
    {
        var catalog = (await _supabaseService.GetActiveServiceCatalogAsync(GetSupabaseAccessToken(), cancellationToken)).ToList();
        _logger.LogInformation("TicketsController.Create catalog: Count={Count}, First={FirstCatalogItem}",
            catalog.Count, catalog.FirstOrDefault());
        ViewBag.ServiceCatalog = catalog;
    }

    private string? GetSupabaseAccessToken()
    {
        return User.FindFirst("supabase_access_token")?.Value;
    }

    private static bool CanTransition(string currentStatus, string nextStatus)
    {
        var workflow = new[]
        {
            "Open",
            "Assigned",
            "In Progress",
            "Resolved",
            "Closed"
        };

        var currentIndex = Array.IndexOf(workflow, currentStatus);
        var nextIndex = Array.IndexOf(workflow, nextStatus);

        if (currentIndex < 0 || nextIndex < 0)
        {
            return false;
        }

        return nextIndex == currentIndex + 1 || (currentIndex == 0 && nextIndex == 1) || (currentIndex == 3 && nextIndex == 4);
    }

    private static string NormalizeStatus(string status)
    {
        return status switch
        {
            "Open" => "Open",
            "Assigned" => "Assigned",
            "In Progress" => "In Progress",
            "Resolved" => "Resolved",
            "Closed" => "Closed",
            _ => status
        };
    }

}
