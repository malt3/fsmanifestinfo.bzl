package examples.java;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Simple string utilities without external dependencies
 * In production, this would use Guava
 */
public class SimpleStringUtils {

    public static List<String> splitWords(String text) {
        List<String> words = new ArrayList<>();
        if (text != null && !text.isEmpty()) {
            for (String word : text.split("\\s+")) {
                if (!word.isEmpty()) {
                    words.add(word);
                }
            }
        }
        return words;
    }

    public static String joinWithCommas(List<String> items) {
        return String.join(", ", items);
    }

    public static String reverseWords(String text) {
        List<String> words = splitWords(text);
        Collections.reverse(words);
        return joinWithCommas(words);
    }
}