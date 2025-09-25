using Android.App;
using Android.Content;
using Android.Content.PM;
using Android.OS;
using AndroidX.Core.App;
using AndroidApp = Android.App.Application;

namespace CobranzasTracker.Platforms.Android.Services;

[Service(Enabled = true, Exported = true, ForegroundServiceType = ForegroundService.TypeLocation, Name = "com.banpro.cobranzastracker.services.LocationForegroundService")]
public class LocationBackgroundService : Service
{
    #region Private Fields
    private const string NotificationChannelId = "location_tracker_channel";
    private const string NotificationChannelName = "Location Tracker Service";
    private const int ServiceNotificationId = 10000;

    #endregion Private Fields

    #region Public Methods

    public override IBinder OnBind(Intent intent) => null;

    public override void OnDestroy()
    {
        base.OnDestroy();
        // Limpiar recursos aquí
    }

    public override StartCommandResult OnStartCommand(Intent intent, StartCommandFlags flags, int startId)
    {
        CreateNotificationChannel();
        var notification = CreateNotification();

        // Start as foreground service (IMPORTANTE: debe hacerse dentro de 5 segundos)
        StartForeground(ServiceNotificationId, notification);

        // Iniciar tu trabajo en segundo plano aquí
        StartBackgroundWork();

        return StartCommandResult.Sticky;
    }

    #endregion Public Methods

    #region Private Methods

    private Notification CreateNotification()
    {
        var intent = new Intent(AndroidApp.Context, typeof(MainActivity));
        intent.AddFlags(ActivityFlags.SingleTop);
        var pendingIntent = PendingIntent.GetActivity(AndroidApp.Context, 0, intent, PendingIntentFlags.Immutable);

        var builder = new NotificationCompat.Builder(this, NotificationChannelId)
            .SetContentTitle("Location Tracker")
            .SetContentText("Tracking your location in background")
            .SetSmallIcon(Resource.Drawable.abc_ab_share_pack_mtrl_alpha) // Usa tu propio icono
            .SetContentIntent(pendingIntent)
            .SetOngoing(true);

        return builder.Build();
    }

    private void CreateNotificationChannel()
    {
        if (Build.VERSION.SdkInt >= BuildVersionCodes.O)
        {
            var channel = new NotificationChannel(
                NotificationChannelId,
                NotificationChannelName,
                NotificationImportance.Low
            );

            var notificationManager = GetSystemService(NotificationService) as NotificationManager;
            notificationManager?.CreateNotificationChannel(channel);
        }
    }

    private void StartBackgroundWork()
    {
        // Aquí inicias tu trabajo de fondo
        // Por ejemplo, iniciar el timer de ubicación
        Task.Run(async () =>
        {
            while (true)
            {
                // Tu lógica de background aquí
                await Task.Delay(TimeSpan.FromMinutes(1));
            }
        });
    }

    #endregion Private Methods
}