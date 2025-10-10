package examples.java;

import com.google.common.base.Joiner;
import com.google.common.base.Splitter;
import com.google.common.collect.ImmutableList;
import java.util.List;

/**
 * Utility library using Guava
 */
public class StringUtils {

    public static List<String> splitWords(String text) {
        return ImmutableList.copyOf(
            Splitter.on(' ')
                .trimResults()
                .omitEmptyStrings()
                .split(text)
        );
    }

    public static String joinWithCommas(List<String> items) {
        return Joiner.on(", ").join(items);
    }

    public static String reverseWords(String text) {
        List<String> words = splitWords(text);
        return joinWithCommas(ImmutableList.copyOf(words).reverse());
    }
}