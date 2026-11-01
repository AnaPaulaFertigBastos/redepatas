using System.Diagnostics;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using rede_patas_backend.Data;
using rede_patas_backend.Models;

// Integration test: creates an isolated database and removes only that database afterwards.
var apiDirectory = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../rede-patas-backend"));
var settings = JsonDocument.Parse(File.ReadAllText(Path.Combine(apiDirectory, "appsettings.Development.json")));
var connectionString = Environment.GetEnvironmentVariable("REDEPATAS_TEST_POSTGRES")
    ?? settings.RootElement.GetProperty("ConnectionStrings").GetProperty("Postgres").GetString()!;
var database = "redepatas_test_" + Guid.NewGuid().ToString("N");
var adminSettings = new NpgsqlConnectionStringBuilder(connectionString) { Database = "postgres", Pooling = false };
await using var admin = new NpgsqlConnection(adminSettings.ConnectionString);
await admin.OpenAsync();
await using (var create = new NpgsqlCommand($"CREATE DATABASE \"{database}\"", admin))
    await create.ExecuteNonQueryAsync();
var testSettings = new NpgsqlConnectionStringBuilder(connectionString) { Database = database };
Process? server = null;
try
{
    var options = new DbContextOptionsBuilder<ApiContext>().UseNpgsql(testSettings.ConnectionString).Options;
    await using var db = new ApiContext(options);
    Check(!db.Database.HasPendingModelChanges(), "migration snapshot matches the model");
    await db.Database.MigrateAsync();

    // Port zero lets the OS allocate an unused local port.
    var listener = new System.Net.Sockets.TcpListener(IPAddress.Loopback, 0);
    listener.Start();
    var port = ((System.Net.IPEndPoint)listener.LocalEndpoint).Port;
    listener.Stop();
    var start = new ProcessStartInfo("dotnet") {
        WorkingDirectory = apiDirectory, UseShellExecute = false, CreateNoWindow = true,
        RedirectStandardOutput = true, RedirectStandardError = true
    };
    start.ArgumentList.Add(Path.Combine(apiDirectory, "bin/Debug/net10.0/rede-patas-backend.dll"));
    start.ArgumentList.Add("--urls");
    start.ArgumentList.Add($"http://127.0.0.1:{port}");
    start.Environment["ConnectionStrings__Postgres"] = testSettings.ConnectionString;
    start.Environment["ASPNETCORE_ENVIRONMENT"] = "Development";
    server = Process.Start(start)!;
    var output = server.StandardOutput.ReadToEndAsync();
    var errors = server.StandardError.ReadToEndAsync();
    using var http = new HttpClient { BaseAddress = new Uri($"http://127.0.0.1:{port}"), Timeout = TimeSpan.FromSeconds(5) };
    var ready = false;
    for (var attempt = 0; attempt < 60; attempt++)
    {
        if (server.HasExited) throw new Exception(await errors + await output);
        try { await http.GetAsync("/api/auth/me"); ready = true; break; }
        catch (HttpRequestException) { await Task.Delay(250); }
    }
    Check(ready, "API starts");
    var invalid = await http.PostAsJsonAsync("/api/auth/register", new { name = " ", email = "invalid", password = "123" });
    Check(invalid.StatusCode == HttpStatusCode.BadRequest, "invalid registration rejected");
    var registered = await http.PostAsJsonAsync("/api/auth/register", new { name = " Ana Silva ", email = "ANA@example.com", password = "senha1234" });
    Check(registered.StatusCode == HttpStatusCode.Created, "registration succeeds");
    var session = (await registered.Content.ReadFromJsonAsync<JsonElement>());
    var user = await db.Usuarios.SingleAsync();
    Check(user.Nome == "Ana Silva" && user.Email == "ana@example.com" && user.Status == "ativo", "user fields persisted and normalized");
    Check(user.SenhaHash != "senha1234" && new PasswordHasher<Usuario>().VerifyHashedPassword(user, user.SenhaHash, "senha1234") != PasswordVerificationResult.Failed, "password stored as a valid hash");
    var refresh = session.GetProperty("refreshToken").GetString()!;
    Check((await db.TokensRenovacao.SingleAsync()).TokenHash != refresh, "refresh token stored as a hash");
    Check(!session.ToString().Contains(user.SenhaHash), "password hash is absent from response");
    var duplicate = await http.PostAsJsonAsync("/api/auth/register", new { name = "Ana", email = "ana@example.com", password = "senha1234" });
    Check(duplicate.StatusCode == HttpStatusCode.Conflict, "duplicate email rejected");
    http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", session.GetProperty("accessToken").GetString());
    Check((await http.GetAsync("/api/auth/me")).StatusCode == HttpStatusCode.OK, "registration access token authenticates");
    var badLogin = await http.PostAsJsonAsync("/api/auth/login", new { email = user.Email, password = "wrong" });
    Check(badLogin.StatusCode == HttpStatusCode.Unauthorized, "wrong password rejected");
    var login = await http.PostAsJsonAsync("/api/auth/login", new { email = "ANA@example.com", password = "senha1234" });
    Check(login.IsSuccessStatusCode, "registered user can log in again");
    var renewed = await http.PostAsJsonAsync("/api/auth/refresh", new { refreshToken = refresh });
    Check(renewed.IsSuccessStatusCode, "session refresh succeeds");
    var replay = await http.PostAsJsonAsync("/api/auth/refresh", new { refreshToken = refresh });
    Check(replay.StatusCode == HttpStatusCode.Unauthorized, "consumed refresh token rejected");
    var newSession = await renewed.Content.ReadFromJsonAsync<JsonElement>();
    var newRefresh = newSession.GetProperty("refreshToken").GetString();
    Check((await http.PostAsJsonAsync("/api/auth/logout", new { refreshToken = newRefresh })).StatusCode == HttpStatusCode.NoContent, "logout succeeds");
    Check((await http.PostAsJsonAsync("/api/auth/refresh", new { refreshToken = newRefresh })).StatusCode == HttpStatusCode.Unauthorized, "logout revokes refresh token");
    Console.WriteLine("All authentication integration checks passed.");
}
finally
{
    if (server is not null) { if (!server.HasExited) server.Kill(entireProcessTree: true); await server.WaitForExitAsync(); server.Dispose(); }
    NpgsqlConnection.ClearAllPools();
    await using var drop = new NpgsqlCommand($"DROP DATABASE \"{database}\" WITH (FORCE)", admin);
    await drop.ExecuteNonQueryAsync();
}

static void Check(bool condition, string message)
{
    if (!condition) throw new Exception("FAIL: " + message);
    Console.WriteLine("PASS: " + message);
}
