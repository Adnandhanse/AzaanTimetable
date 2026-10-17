package com.adnandhanse.azan_screen_events;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;

/** Registered in every Flutter engine, including the foreground service engine. */
public final class AzanScreenEventsPlugin implements FlutterPlugin, EventChannel.StreamHandler {
    private Context context;
    private EventChannel channel;
    private BroadcastReceiver receiver;

    @Override public void onAttachedToEngine(FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new EventChannel(binding.getBinaryMessenger(), "islam_connect/screen_events");
        channel.setStreamHandler(this);
    }

    @Override public void onListen(Object arguments, EventChannel.EventSink events) {
        onCancel(null);
        receiver = new BroadcastReceiver() {
            @Override public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                if (Intent.ACTION_SCREEN_OFF.equals(action) || Intent.ACTION_SCREEN_ON.equals(action)) {
                    events.success(action);
                }
            }
        };
        IntentFilter filter = new IntentFilter(Intent.ACTION_SCREEN_OFF);
        filter.addAction(Intent.ACTION_SCREEN_ON);
        // These are exclusively protected system broadcasts. No exported flag is required.
        context.registerReceiver(receiver, filter);
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
        context = null;
    }
}
