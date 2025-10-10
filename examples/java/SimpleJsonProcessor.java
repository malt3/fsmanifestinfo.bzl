package examples.java;

import java.util.Map;

/**
 * Simple JSON processor without external dependencies
 * In production, this would use Gson
 */
public class SimpleJsonProcessor {

    public String toJson(Map<String, Object> data) {
        StringBuilder json = new StringBuilder("{\n");
        int count = 0;
        for (Map.Entry<String, Object> entry : data.entrySet()) {
            if (count > 0) json.append(",\n");
            json.append("  \"").append(entry.getKey()).append("\": ");

            Object value = entry.getValue();
            if (value instanceof String) {
                json.append("\"").append(value).append("\"");
            } else {
                json.append(value);
            }
            count++;
        }
        json.append("\n}");
        return json.toString();
    }
}