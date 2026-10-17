package com.adnandhanse.azan_screen_events;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;

/** Registered in every Flutter engine, including the foreground service engine. */
public final class AzanScreenEventsPlugin implements FlutterPlugin, EventChannel.StreamHandler {
    private Context context;
    private EventChannel channel;
    private MethodChannel control;
    private static final String STOP_ACTION = "com.adnandhanse.islamconnect.STOP_AZAN";
    // Synchronize across background/action/main Flutter engines in this process.
    private static synchronized long stopSequence(Context context, boolean increment) {
        android.content.SharedPreferences prefs = context.getSharedPreferences("azan_control", Context.MODE_PRIVATE);
        long value = prefs.getLong("stop_sequence", 0L);
        if (increment) {
            value++;
            if (!prefs.edit().putLong("stop_sequence", value).commit()) {
                throw new IllegalStateException("Unable to persist stop signal");
            }
        }
        return value;
    }
    private BroadcastReceiver receiver;

    @Override public void onAttachedToEngine(FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new EventChannel(binding.getBinaryMessenger(), "islam_connect/screen_events");
        channel.setStreamHandler(this);
        control = new MethodChannel(binding.getBinaryMessenger(), "islam_connect/azan_control");
        control.setMethodCallHandler((call, result) -> {
            try {
                if ("stop".equals(call.method)) {
                    stopSequence(context, true);
                    context.sendBroadcast(new Intent(STOP_ACTION).setPackage(context.getPackageName()));
                    result.success(null);
                } else if ("stopSequence".equals(call.method)) {
                    result.success(stopSequence(context, false));
                } else {
                    result.notImplemented();
                }
            } catch (RuntimeException error) {
                result.error("azan_control", error.getMessage(), null);
            }
        });
    }

    @Override public void onListen(Object arguments, EventChannel.EventSink events) {
        onCancel(null);
        receiver = new BroadcastReceiver() {
            @Override public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                if (Intent.ACTION_SCREEN_OFF.equals(action) || Intent.ACTION_SCREEN_ON.equals(action) || STOP_ACTION.equals(action)) {
                    events.success(action);
                }
            }
        };
        IntentFilter filter = new IntentFilter(Intent.ACTION_SCREEN_OFF);
        filter.addAction(Intent.ACTION_SCREEN_ON);
        filter.addAction(STOP_ACTION);
        if (Build.VERSION.SDK_INT >= 33) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            context.registerReceiver(receiver, filter);
        }
    }

    @Override public void onCancel(Object arguments) {
        if (receiver != null) {
            context.unregisterReceiver(receiver);
            receiver = null;
        }
    }

    @Override public void onDetachedFromEngine(FlutterPluginBinding binding) {
        onCancel(null);
        channel.setStreamHandler(null);
        control.setMethodCallHandler(null);
        context = null;
    }
}
