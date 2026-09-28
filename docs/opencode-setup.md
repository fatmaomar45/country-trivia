# OpenCode PR Review Setup

This repo uses GitHub Actions with OpenCode's **Big Pickle** model to automatically review pull requests.

## How It Works

When a PR is opened or updated, the workflow:
1. Checks out the repository
2. Sets up OpenCode CLI
3. Runs a review using the `opencode/big-pickle` model
4. Posts the review as a PR comment

## Setting Up the API Key

### 1. Obtain an OpenCode API Key

1. Go to [OpenCode](https://opencode.ai) and sign in
2. Navigate to **Settings** → **API Keys**
3. Click **Create new key**
4. Copy the generated key (starts with `sk-`)

### 2. Add the Key to GitHub Repository Secrets

1. Go to the repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Set **Name** to `OPENCODE_API_KEY`
5. Paste your OpenCode API key as the **Value**
6. Click **Add secret**

### 3. Verify the Setup

1. Open a pull request
2. The workflow should automatically trigger
3. Check the **Actions** tab to see the workflow run
4. Once complete, a review comment will be posted on the PR

## Workflow File

The workflow is defined in `.github/workflows/pr-review.yml`.

## Model

- **Model ID:** `opencode/big-pickle`
- **Provider:** OpenCode Zen
- **Cost:** Free (0 USD per million tokens)
