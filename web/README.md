# ServiceHub IT

ServiceHub IT is an ASP.NET Core 8 MVC application for IT help desk, asset management, ticketing, and reporting.

## Overview

This application includes:
- Authentication and authorization with cookie-based login
- Ticket, asset, department, maintenance, notification, and knowledge base management
- Dashboard views and reporting features
- Supabase integration for backend data access
- PDF processing and document import support
- Machine learning ticket prediction model
- Responsive Bootstrap 5 UI and standard MVC layout

## Prerequisites

- .NET 8 SDK installed
- A Supabase project with REST API access
- Optional: Visual Studio 2022/2023, Visual Studio Code, or another C# editor

## Configuration

Keep Supabase credentials out of source control. The app can start without them, but sign-in and Supabase-backed features require a Supabase project and credentials.

From the `web` directory, set the values with .NET User Secrets:

```powershell
dotnet user-secrets init --project ".\ServiceHub IT.csproj"
dotnet user-secrets set "Supabase:Url" "https://<your-supabase-project>.supabase.co" --project ".\ServiceHub IT.csproj"
dotnet user-secrets set "Supabase:ApiKey" "<your-supabase-api-key>" --project ".\ServiceHub IT.csproj"
dotnet user-secrets set "Supabase:RedirectUrl" "http://localhost:5000/Auth/Login" --project ".\ServiceHub IT.csproj"
```

Alternatively, set the corresponding `Supabase__Url`, `Supabase__ApiKey`, and `Supabase__RedirectUrl` environment variables.

The optional `supabase_profiles.py` helper uses `SUPABASE_URL` and `SUPABASE_API_KEY`; it also accepts `SUPABASE_SERVICE_ROLE_KEY` when needed.

## Run locally

1. Open a terminal in this directory:

```powershell
cd web
```

2. Restore packages and run the app (the first run restores automatically):

```powershell
dotnet run --urls http://localhost:5000
```

3. Open the web browser at:

```text
http://localhost:5000
```

The default application route is configured to `Auth/Login`.

## Project structure

- `Controllers/` - MVC controllers for pages and API actions
- `Models/` - domain models, view models, and configuration classes
- `Views/` - Razor views and shared layouts
- `Services/` - application services, Supabase integration, PDF processing, reporting, and ML
- `Repositories/` - data access and repository base classes
- `Interfaces/` - service and repository interfaces
- `DTOs/` - data transfer objects
- `Utilities/` - shared constants and helper code
- `Middleware/` - request logging and pipeline middleware
- `wwwroot/` - static assets, CSS, JS, and images

## Key packages

- `Supabase` for Supabase REST API integration
- `Microsoft.ML` for machine learning ticket prediction
- `DocumentFormat.OpenXml` for working with Office documents
- `UglyToad.PdfPig` for PDF parsing and processing

## Notes

- The app uses cookie authentication.
- Authorization is enabled globally, so users must sign in to access protected routes.
- If you change the local port or hostname, update `Supabase:RedirectUrl` accordingly.

## Troubleshooting

- If the app does not start, verify your .NET SDK installation with:

```powershell
dotnet --info
```

- If login or Supabase fails, confirm that the Supabase User Secrets or environment variables are set.
- If you use a different development port, update the redirect URL in configuration.
