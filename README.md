
# Zip Deploy Azure Function - Modernized with Azure Developer CLI

This project demonstrates how to deploy an Azure Function using **ZipDeploy with enhanced security** and modern infrastructure practices. The solution has been **modernized to favor the recommended Azure Developer CLI (azd) approach** for deployment, while maintaining support for traditional ARM template deployment.

> **Note**: This template uses a dedicated **Elastic Premium plan** for predictable performance and advanced networking features. If you prefer a **serverless consumption billing model**, we recommend using the [Flex Consumption quickstart](https://learn.microsoft.com/en-us/azure/azure-functions/create-first-function-azure-developer-cli?tabs=linux%2Cget%2Cbash%2Cpowershell&pivots=programming-language-csharp) which inherently uses secure zip deploy with an updated mechanism optimized for serverless workloads and also offers networking features like VNET.

## 🚀 **Recommended: Azure Developer CLI (AZD) Deployment**

The **preferred method** uses Azure Developer CLI with automated zip deployment to secure blob storage. This approach eliminates storage keys and uses modern identity-based authentication.

### **Key Modern Features:**
- 🔒 **Secure Blob Storage**: Uses User-Assigned Managed Identity (no storage keys)
- ⚡ **Elastic Premium Linux**: Ideal dedicated instance performance with scaling options
- 🎯 **Azure Verified Modules (AVM)**: Enterprise-grade, Microsoft-maintained infrastructure templates
- 🔑 **Zero Secrets**: All authentication uses Azure Active Directory identities
- 📦 **Automated Deployment**: Builds, packages, and deploys in one command


### Pre-requisites

Before you begin, ensure the following tools are installed locally:

- **Azure CLI (`az`)**: [Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Azure Developer CLI (`azd`)**: [Install Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/cli/install-azure-developer-cli)
- **Azure Functions Core Tools (`func`)**: [Install Azure Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local#install-the-azure-functions-core-tools)

After installation, sign in to your Azure account:

```sh
az login
```

### **Quick Start:**
```bash
# Clone and navigate to the project
git clone https://github.com/paulyuk/ZipDeploy-AzFunc.git
cd ZipDeploy-AzFunc

# Login and deploy everything
azd auth login
azd up
```

> **Note** it is expected at the very end of `azd up` to see a message that you used a run from package command, and this is by design and ignorable.  Don't worry.
```shell
--------------------------------------------------------------------------------
"Run-From-Zip is set to a remote URL using WEBSITE_RUN_FROM_PACKAGE or WEBSITE_USE_ZIP app setting. Deployment is not supported in this configuration."
--------------------------------------------------------------------------------
```

That's it! The `azd up` command will:
1. **Provision** infrastructure using [main.bicep](infra/main.bicep)
2. **Build** your .NET 8 Function App
3. **Package** it into a secure zip file
4. **Upload** to blob storage using managed identity
5. **Deploy** and restart your Function App

### **How It Works:**
- **Infrastructure**: Uses Azure Verified Modules for secure, enterprise-grade resources
- **Zip Deploy**: Uploads function package to private blob container
- **Authentication**: User-Assigned Managed Identity handles all Azure service authentication
- **No Keys**: Eliminates storage account keys and connection strings entirely

### **Deployment Scripts:**
The deployment process uses automated scripts that can be adapted for various CI/CD scenarios:
- **Local Development**: [scripts/deploy.sh](scripts/deploy.sh) or [scripts/deploy.ps1](scripts/deploy.ps1)
- **GitHub Actions**: Easily adaptable for CI/CD pipelines
- **Azure DevOps**: Compatible with Azure CLI tasks
- **Any CI/CD Tool**: Works with any system that supports Azure CLI

### Testing the deployed function

From the Azure Portal, navigate to your deployed Function App. You can find the function URL in the "Functions" section. Click on the URL, or copy-paste it to your browser to test the function. You should see a blue screen with a message "Your Functions 4.0 app is up and running". That means your function App is deployed. To test the api append `/api/GetAdventurers` to the URL to see the function response consisting of a list of 20 adventurers in JSON format.

## 📋 **Alternative: ARM Template Deployment**

For scenarios where you need direct ARM template deployment, you can still use the one-click deployment button. **Note**: This method requires you to upload your zip file separately after infrastructure deployment.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fpaulyuk%2FZipDeploy-AzFunc%2Frefs%2Fheads%2Fepmigration%2Fazuredeploy.json)

The ARM template ([azuredeploy.json](azuredeploy.json)) deploys the same secure infrastructure but requires manual zip upload to the created blob container.

## 📚 **Learn More**

To learn more about the original concept, refer to the blog post on [How to Deploy a .NET isolated Azure Function using Zip Deploy in One-Click](https://www.frankysnotes.com/2024/04/how-to-deploy-net-isolated-azure.html) on frankysnotes.com.

There is also a video on [YouTube](https://www.youtube.com/watch?v=LHJTUvjw9po):

[![YouTube preview](docs/images/c5m-ep70b.gif)](https://www.youtube.com/watch?v=LHJTUvjw9po)

