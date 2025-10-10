package examples.java;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonObject;
import java.util.Map;

/**
 * Library for JSON processing using Gson
 */
public class JsonProcessor {
    private final Gson gson;

    public JsonProcessor() {
        this.gson = new GsonBuilder()
            .setPrettyPrinting()
            .create();
    }

    public String toJson(Map<String, Object> data) {
        return gson.toJson(data);
    }

    public JsonObject parse(String json) {
        return gson.fromJson(json, JsonObject.class);
    }

    public String prettyPrint(String json) {
        JsonObject obj = parse(json);
        return gson.toJson(obj);
    }
}