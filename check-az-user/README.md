# CheckAzUser

This utility makes use of the [Microsoft Authentication Library (MSAL) for Java](https://github.com/AzureAD/microsoft-authentication-library-for-java) to check if a specific userID with a password is able to sign-in on an [Azure Active Directory](https://azure.microsoft.com/).

This small utility is based on:
https://github.com/Azure-Samples/ms-identity-java-desktop/

## Usage

The usage of this utility is very simple: just provide an user ID (`[username]@[domain]`) and a password, launch the program and wait for the resulting output. This output can be `OK` if the sign-in was successfull, or `ERROR` followed by a description if something was wrong.

A Client ID must be provided on the `application.properties` file or as parameter.

```
usage: java -jar check-az-user.jar
 -p,--password <arg>   User password
 -u,--user <arg>       User ID in the form [username]@[domain]
 -c,--client <arg>     Client ID of an app registered on an AzureAD tenant
 -v,--verbose          Verbose mode
 -h,--help             Show this help 
```

## How to run this utility

To run this utility, you'll need:

- A Working installation of Java and Maven.
- An Internet connection.
- An Azure Active Directory (Azure AD) tenant. For more information on how to get an Azure AD tenant, see [How to get an Azure AD tenant](https://azure.microsoft.com/en-us/documentation/articles/active-directory-howto-tenant/).
- A user account in your Azure AD tenant. It will not work with a Microsoft account (formerly Windows Live account). Therefore, if you signed in to the [Azure portal](https://portal.azure.com) with a Microsoft account and have never created a user account in your directory before, you need to do that now.


### First step: choose the Azure AD tenant where you want to create your applications

As a first step you'll need to:

1. Sign in to the [Azure portal](https://portal.azure.com) using either a work or school account or a personal Microsoft account.
2. If your account is present in more than one Azure AD tenant, select your profile at the top right corner in the menu on top of the page, and then **switch directory**. Change your portal session to the desired Azure AD tenant.
3. In the portal menu, click on **All services**, and choose **Azure Active Directory**.

> In the next steps, you might need the tenant name (or directory name) or the tenant ID (or directory ID). These are presented in the **Properties** of the Azure Active Directory window respectively as *Name* and *Directory ID*

#### Register the app app (Java-Console-Application)

1. Navigate to the Microsoft identity platform for developers [App registrations](https://go.microsoft.com/fwlink/?linkid=2083908) page.

2. Click **New registration**.

3. When the **Register an application page** appears, enter your application's registration information:
   - In the **Name** section, enter a meaningful application name that will be displayed to users of the app, for example `Check-User-Application`.
   - In the **Supported account types** section, select **Accounts in any organizational directory**.

4. Select **Register** to create the application.

5. In the app's registration **Overview** page, find the **Application (client) ID** value and record it for later. You'll need it to configure the APP_ID value in `UsernamePasswordFlow.Java` later.

6. In the Application menu blade, select **Manifest**, and:
   - In the manifest editor, set the `allowPublicClient` property to **true**
   - Select **Save** in the bar above the manifest editor.

7. In the Application menu blade, select **API permissions**
   - Ensure that the **User.Read** permission is listed in the permissions list (which is automatically added when you register your application).

8. At this stage permissions are assigned correctly but the client app does not allow interaction.
   Therefore no consent can be presented via UI and accepted to use the service app.
   Click the **Grant/revoke admin consent for {tenant}** button, and then select **Yes** when you are asked if you want to grant consent for the requested permissions for all accounts in the tenant.
   You need to be an Azure AD tenant admin to do this.

### Second step: Configure the sample to use your Azure AD tenant

In the steps below, ClientID is the same as Application ID or AppId.

#### Configure the app project

1. Rename the file `/application-example.properties` to `/application.properties` (or make a copy of it)
2. Open the `application.properties` file
3. Set the `CLIENT_ID` property to the client ID value you recorded earlier

Note: You can provide also the Client ID as a parameter to the CLI.

### Third step: Run the sample

From your shell or command line:

- `$ mvn clean compile assembly:single`

This will generate a `check-az-user-[version].jar` file in your `/target` directory. Run this using your Java executable like below:

- `$ java -jar target/check-az-user-[version].jar -u <username@domain> -p <password> [-c CLIENT-ID] [-v]`

### You're done

For more information about the insights of the password-based sign-in process, see:
https://github.com/Azure-Samples/ms-identity-java-desktop/tree/master/Username-Password-Flow


### TODO
- The password should be encrypted to avoid leaving it exposed in the system logs
- Use [log4j](https://logging.apache.org/log4j/2.x/) to display messages instead of `System.out.println` calls