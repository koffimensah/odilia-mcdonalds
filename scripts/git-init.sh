#!/bin/bash

# ============================================
# Git Repository Initialization Script
# Odilia Application - McDonald's
# ============================================

echo "╔════════════════════════════════════════════╗"
echo "║   Git Repository Setup - Odilia App       ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git is not installed. Please install Git first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Git is installed${NC}"
echo ""

# Check if already a git repository
if [ -d .git ]; then
    echo -e "${YELLOW}⚠️  This directory is already a Git repository.${NC}"
    read -p "Do you want to continue? (yes/no): " CONTINUE
    if [ "$CONTINUE" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi
    echo ""
fi

# Security check
echo "🔒 Security Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for common sensitive patterns
echo "Checking for sensitive data..."
SENSITIVE_FOUND=0

if grep -r "password.*=.*[^a-very-complex-password-here]" . --exclude-dir=.git --exclude="*.sh" -q 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Found non-default passwords in files${NC}"
    SENSITIVE_FOUND=1
fi

if grep -r "api.key\|apikey\|api_key" . --exclude-dir=.git --exclude="*.sh" -q 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Found potential API keys${NC}"
    SENSITIVE_FOUND=1
fi

if [ -f .env ]; then
    echo -e "${YELLOW}⚠️  .env file exists (will be ignored)${NC}"
fi

if [ $SENSITIVE_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ No obvious sensitive data found${NC}"
fi

echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Review docker-compose.yml and ensure passwords are secured!${NC}"
echo ""

read -p "Continue with Git initialization? (yes/no): " CONTINUE
if [ "$CONTINUE" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""

# Initialize Git repository
echo "📦 Initializing Git Repository"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -d .git ]; then
    git init
    echo -e "${GREEN}✅ Git repository initialized${NC}"
else
    echo -e "${YELLOW}Repository already initialized${NC}"
fi

echo ""

# Configure Git (if not already configured)
echo "⚙️  Git Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

GIT_USER=$(git config user.name)
GIT_EMAIL=$(git config user.email)

if [ -z "$GIT_USER" ]; then
    read -p "Enter your name: " USER_NAME
    git config user.name "$USER_NAME"
    echo -e "${GREEN}✅ Name configured: $USER_NAME${NC}"
else
    echo -e "Name: ${GREEN}$GIT_USER${NC}"
fi

if [ -z "$GIT_EMAIL" ]; then
    read -p "Enter your email: " USER_EMAIL
    git config user.email "$USER_EMAIL"
    echo -e "${GREEN}✅ Email configured: $USER_EMAIL${NC}"
else
    echo -e "Email: ${GREEN}$GIT_EMAIL${NC}"
fi

echo ""

# Ensure scripts directory exists
echo "📁 Checking Project Structure"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -d scripts ]; then
    mkdir -p scripts
    echo -e "${GREEN}✅ Created scripts directory${NC}"
fi

if [ ! -d backups ]; then
    mkdir -p backups
    touch backups/.gitkeep
    echo -e "${GREEN}✅ Created backups directory${NC}"
fi

echo ""

# Check for required files
echo "📄 Checking Required Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

MISSING_FILES=0

if [ ! -f docker-compose.yml ]; then
    echo -e "${RED}❌ docker-compose.yml not found${NC}"
    MISSING_FILES=1
else
    echo -e "${GREEN}✅ docker-compose.yml${NC}"
fi

if [ ! -f README.md ]; then
    echo -e "${RED}❌ README.md not found${NC}"
    MISSING_FILES=1
else
    echo -e "${GREEN}✅ README.md${NC}"
fi

if [ ! -f .gitignore ]; then
    echo -e "${YELLOW}⚠️  .gitignore not found (will be created)${NC}"
    MISSING_FILES=1
else
    echo -e "${GREEN}✅ .gitignore${NC}"
fi

if [ ! -f .dockerignore ]; then
    echo -e "${YELLOW}⚠️  .dockerignore not found (recommended)${NC}"
else
    echo -e "${GREEN}✅ .dockerignore${NC}"
fi

echo ""

if [ $MISSING_FILES -eq 1 ]; then
    echo -e "${YELLOW}⚠️  Some files are missing. Please ensure all required files are present.${NC}"
    read -p "Continue anyway? (yes/no): " CONTINUE
    if [ "$CONTINUE" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi
    echo ""
fi

# Stage files
echo "📦 Staging Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

git add .

echo -e "${GREEN}✅ Files staged${NC}"
echo ""

# Show what will be committed
echo "📋 Files to be committed:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
git status --short
echo ""

# Ask for commit message
echo "💬 Commit Message"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Enter commit message (or press Enter for default): " COMMIT_MSG

if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="Initial commit: Odilia application for McDonald's

- Add docker-compose.yml with 12 microservices
- Add comprehensive README with setup instructions
- Add Redis Sentinel for high availability
- Add PostgreSQL replication
- Add monitoring and management scripts
- Add .gitignore and .dockerignore"
fi

# Commit
git commit -m "$COMMIT_MSG"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Changes committed${NC}"
else
    echo -e "${RED}❌ Commit failed${NC}"
    exit 1
fi

echo ""

# Ask about remote repository
echo "🌐 Remote Repository"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Do you want to add a remote repository? (yes/no): " ADD_REMOTE

if [ "$ADD_REMOTE" = "yes" ]; then
    echo ""
    echo "Options:"
    echo "1. GitHub HTTPS (e.g., https://github.com/username/repo.git)"
    echo "2. GitHub SSH (e.g., git@github.com:username/repo.git)"
    echo "3. Other"
    echo ""
    read -p "Choose option (1-3): " REMOTE_OPTION
    echo ""
    
    read -p "Enter remote repository URL: " REMOTE_URL
    
    # Check if remote already exists
    if git remote | grep -q "origin"; then
        echo -e "${YELLOW}⚠️  Remote 'origin' already exists${NC}"
        read -p "Remove and re-add? (yes/no): " REMOVE_REMOTE
        if [ "$REMOVE_REMOTE" = "yes" ]; then
            git remote remove origin
            echo -e "${GREEN}✅ Removed existing remote${NC}"
        fi
    fi
    
    git remote add origin "$REMOTE_URL"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Remote added: $REMOTE_URL${NC}"
        echo ""
        
        read -p "Push to remote now? (yes/no): " PUSH_NOW
        
        if [ "$PUSH_NOW" = "yes" ]; then
            # Determine default branch
            DEFAULT_BRANCH=$(git symbolic-ref --short HEAD)
            
            echo "Pushing to $DEFAULT_BRANCH..."
            git push -u origin "$DEFAULT_BRANCH"
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Successfully pushed to remote${NC}"
            else
                echo -e "${RED}❌ Push failed. You may need to authenticate.${NC}"
                echo "Try: git push -u origin $DEFAULT_BRANCH"
            fi
        else
            echo "To push later, run:"
            echo "  git push -u origin $(git symbolic-ref --short HEAD)"
        fi
    else
        echo -e "${RED}❌ Failed to add remote${NC}"
    fi
fi

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║            Setup Complete! 🎉              ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "📊 Repository Status:"
git log --oneline -1
echo ""
echo "🔗 Remote:"
git remote -v
echo ""
echo "📝 Next Steps:"
echo "  1. Review your commit: git log"
echo "  2. Check remote connection: git remote -v"
echo "  3. View on GitHub (if pushed)"
echo "  4. Add collaborators if needed"
echo "  5. Set up branch protection rules"
echo ""
echo "💡 Useful Commands:"
echo "  git status           - Check current status"
echo "  git log --oneline    - View commit history"
echo "  git push             - Push changes"
echo "  git pull             - Get updates"
echo ""
echo "🎯 Your repository is ready!"
echo ""