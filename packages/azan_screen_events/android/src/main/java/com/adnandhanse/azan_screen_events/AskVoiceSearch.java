package com.adnandhanse.azan_screen_events;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.speech.RecognizerIntent;
import java.util.ArrayList;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

/** Uses the installed recognizer's visible activity, never a background mic. */
final class AskVoiceSearch implements PluginRegistry.ActivityResultListener {
    private static final int REQUEST = 48271;
    private ActivityPluginBinding binding;
    private MethodChannel.Result pending;

    void attach(ActivityPluginBinding value) {
        binding = value;
        value.addActivityResultListener(this);
    }
    void detach(boolean configurationChange) {
        if (binding != null) binding.removeActivityResultListener(this);
        binding = null;
        if (!configurationChange) cancel();
    }
    void cancel() {
        if (pending != null) { pending.success(null); pending = null; }
    }
    void listen(String locale, MethodChannel.Result result) {
        if (binding == null) {
            result.error("unavailable", "Open voice search from the app screen.", null);
            return;
        }
        if (pending != null) {
            result.error("busy", "Voice search is already open.", null);
            return;
        }
        Intent intent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale == null ? "hi-IN" : locale);
        intent.putExtra(RecognizerIntent.EXTRA_PROMPT, "Apna sawal boliye");
        intent.putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1);
        pending = result;
        try {
            binding.getActivity().startActivityForResult(intent, REQUEST);
        } catch (ActivityNotFoundException e) {
            pending = null;
            result.error("unavailable", "No speech recognition app is installed. Please type your question.", null);
        } catch (RuntimeException e) {
            pending = null;
            result.error("voice_failed", "Voice search could not start. Please type your question.", null);
        }
    }
    @Override public boolean onActivityResult(int request, int code, Intent data) {
        if (request != REQUEST) return false;
        if (pending != null) {
            MethodChannel.Result result = pending;
            pending = null;
            ArrayList<String> words = data == null ? null : data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS);
            result.success(code == Activity.RESULT_OK && words != null && !words.isEmpty() ? words.get(0) : null);
        }
        return true;
    }
}
