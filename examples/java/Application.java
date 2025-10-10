package examples.java;

import com.google.common.io.Resources;
import com.google.devtools.build.runfiles.Runfiles;
import org.apache.commons.cli.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Main application demonstrating FSManifestInfo with real dependencies
 */
public class Application {
    private static final Logger logger = LoggerFactory.getLogger(Application.class);

    private final JsonProcessor jsonProcessor;
    private String configContent;

    public Application() throws IOException {
        this.jsonProcessor = new JsonProcessor();

        // Load config using Bazel runfiles library
        Runfiles runfiles = Runfiles.create();
        String configPath = runfiles.rlocation("_main/config/app.config");
        this.configContent = Files.readString(Paths.get(configPath), StandardCharsets.UTF_8);
        logger.info("Loaded config from Bazel runfiles");
    }

    public void run(String[] args) {
        logger.info("Starting FSManifestInfo Example Application");
        logger.info("Config loaded: {}", configContent.split("\n")[0]);

        // Parse command line arguments
        Options options = new Options();
        options.addOption("m", "message", true, "Message to process");
        options.addOption("j", "json", false, "Output as JSON");
        options.addOption("r", "reverse", false, "Reverse word order");

        CommandLineParser parser = new DefaultParser();
        try {
            CommandLine cmd = parser.parse(options, args);

            String message = cmd.getOptionValue("message",
                "Hello from FSManifestInfo Java Application with Third-Party Dependencies");

            if (cmd.hasOption("reverse")) {
                message = StringUtils.reverseWords(message);
            }

            List<String> words = StringUtils.splitWords(message);

            if (cmd.hasOption("json")) {
                Map<String, Object> output = new HashMap<>();
                output.put("message", message);
                output.put("words", words);
                output.put("wordCount", words.size());
                output.put("config", configContent.split("\n")[0]);

                System.out.println(jsonProcessor.toJson(output));
            } else {
                System.out.println("=== FSManifestInfo Java Application ===");
                System.out.println("Message: " + message);
                System.out.println("Words: " + StringUtils.joinWithCommas(words));
                System.out.println("Word count: " + words.size());
                System.out.println("Config: " + configContent.split("\n")[0]);
                System.out.println();
                System.out.println("This demonstrates:");
                System.out.println("- Java libraries (json_lib, utils_lib)");
                System.out.println("- External deps (Guava, Gson, SLF4J, Commons CLI)");
                System.out.println("- Data dependencies (config files)");
                System.out.println("- Layer separation (platform/external/application)");
            }

        } catch (ParseException e) {
            logger.error("Failed to parse arguments", e);
            HelpFormatter formatter = new HelpFormatter();
            formatter.printHelp("application", options);
        }
    }

    public static void main(String[] args) {
        try {
            new Application().run(args);
        } catch (Exception e) {
            logger.error("Application failed", e);
            System.exit(1);
        }
    }
}
