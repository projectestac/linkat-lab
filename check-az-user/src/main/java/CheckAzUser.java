// Based on: https://github.com/Azure-Samples/ms-identity-java-desktop/tree/master/Username-Password-Flow
// Licensed under the MIT License.

// TODO: The password should be encrypted to avoid leaving it exposed in the system logs
// TODO: Use log4j to display messages, instead of `System.out.println`

import com.microsoft.aad.msal4j.IAccount;
import com.microsoft.aad.msal4j.IAuthenticationResult;
import com.microsoft.aad.msal4j.MsalException;
import com.microsoft.aad.msal4j.PublicClientApplication;
import com.microsoft.aad.msal4j.SilentParameters;
import com.microsoft.aad.msal4j.UserNamePasswordParameters;

import java.util.Properties;
import java.util.Collections;
import java.util.Set;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.HelpFormatter;

public class CheckAzUser {

    private static String authority;
    private static Set<String> scope;
    private static String clientId;
    private static String username;
    private static String password;
    private static boolean verbose = false;

    public static void main(String args[]) {
        try {

            Properties settings = new Properties();
            settings.load(CheckAzUser.class.getResourceAsStream("/application.properties"));

            Options options = new Options();
            options.addOption("u", "user", true, "User ID in the form [username]@[domain]");
            options.addOption("p", "password", true, "User password");
            options.addOption("c", "client", true, "Client ID of an app registered on an AzureAD tenant");
            options.addOption("v", "verbose", false, "Verbose mode");
            options.addOption("h", "help", false, "Show this help");

            CommandLineParser parser = new DefaultParser();
            CommandLine cmd = parser.parse(options, args);

            if (args.length == 0 || cmd.hasOption("h")) {
                HelpFormatter formatter = new HelpFormatter();
                formatter.printHelp("java -jar check-az-user.jar", options);
                System.exit(0);
            }

            if (!cmd.hasOption("u") || !cmd.hasOption("p"))
                throw new Exception("Missing parameters. Please provide a valid user ID and password.");

            username = cmd.getOptionValue("u");
            if (username.indexOf("@") < 1)
                throw new Exception("The user ID should be an expression like: [username]@[domain]");

            password = cmd.getOptionValue("p");

            verbose = cmd.hasOption("v");

            clientId = cmd.getOptionValue("c", settings.getProperty("CLIENT_ID"));

            authority = settings.getProperty("AUTHORITY", "https://login.microsoftonline.com/organizations/");
            scope = Collections.singleton(settings.getProperty("SCOPE", "user.read"));

            PublicClientApplication pca = PublicClientApplication.builder(clientId).authority(authority).build();

            // Get list of accounts from the application's token cache, and search them for
            // the configured username
            // getAccounts() will be empty on this first call, as accounts are added to the
            // cache when acquiring a token
            Set<IAccount> accountsInCache = pca.getAccounts().join();
            IAccount account = getAccountByUsername(accountsInCache, username);

            // Attempt to acquire token when user's account is not in the application's
            // token cache
            IAuthenticationResult result = acquireTokenUsernamePassword(pca, scope, account, username, password);

            accountsInCache = pca.getAccounts().join();
            account = getAccountByUsername(accountsInCache, username);

            // Attempt to acquire token again, now that the user's account and a token are
            // in the application's token cache
            result = acquireTokenUsernamePassword(pca, scope, account, username, password);

            if (verbose) {
                System.out.println("User:    " + result.account().username());
                System.out.println("Expires: " + result.expiresOnDate());
                System.out.println("Account: " + result.account().toString());
            }

            System.out.println("OK");
            System.exit(0);

        } catch (Exception ex) {
            System.err.println("ERROR: " + ex.getMessage());
            System.exit(1);
        }
    }

    private static IAuthenticationResult acquireTokenUsernamePassword(PublicClientApplication pca, Set<String> scope,
            IAccount account, String username, String password) throws Exception {
        IAuthenticationResult result;
        try {
            SilentParameters silentParameters = SilentParameters.builder(scope).account(account).build();
            // Try to acquire token silently. This will fail on the first
            // acquireTokenUsernamePassword() call
            // because the token cache does not have any data for the user you are trying to
            // acquire a token for
            result = pca.acquireTokenSilently(silentParameters).join();
            if (verbose)
                System.out.println("Token retrieved from cache");
        } catch (Exception ex) {
            if (ex.getCause() instanceof MsalException) {
                if (verbose)
                    System.out.println("Token for current user not found in cache: " + ex.getCause());
                UserNamePasswordParameters parameters = UserNamePasswordParameters
                        .builder(scope, username, password.toCharArray()).build();
                // Try to acquire a token via username/password. If successful, you should see
                // the token and account information printed out to console
                result = pca.acquireToken(parameters).join();
                if (verbose)
                    System.out.println("New token acquired");
            } else {
                // Handle other exceptions accordingly
                throw ex;
            }
        }
        return result;
    }

    /**
     * Helper function to return an account from a given set of accounts based on
     * the given username, or return null if no accounts in the set match
     */
    private static IAccount getAccountByUsername(Set<IAccount> accounts, String username) {
        if (accounts.isEmpty()) {
            if (verbose)
                System.out.println("No accounts in cache");
        } else {
            if (verbose)
                System.out.println("Accounts in cache: " + accounts.size());
            for (IAccount account : accounts) {
                if (account.username().equals(username)) {
                    return account;
                }
            }
        }
        return null;
    }
}
