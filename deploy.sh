#!/bin/bash
set -e

PROJECT_ID="downstream-181e2"
REGION="us-central1"
SERVICE_NAME="downstream"

echo "=== Downstream Cloud Run Deployment ==="

# Load environment variables from server/.env
if [ -f server/.env ]; then
  echo "Loading environment from server/.env..."
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ -n "$line" && ! "$line" =~ ^# ]]; then
      key="${line%%=*}"
      value="${line#*=}"
      export "$key=$value"
    fi
  done < server/.env
fi

# Verify required env vars
if [ -z "$TMDB_API_KEY" ]; then
  echo "Error: TMDB_API_KEY not set"
  exit 1
fi
if [ -z "$FIREBASE_SERVICE_ACCOUNT" ]; then
  echo "Error: FIREBASE_SERVICE_ACCOUNT not set"
  exit 1
fi

# Step 1: Build Flutter web frontend
echo ""
echo "1. Building Flutter web frontend..."
cd frontend
flutter build web --release --dart-define=dart.vm.product=true
cd ..

# Step 2: Copy web build to server static folder
echo ""
echo "2. Copying web build to server..."
rm -rf server/static
cp -r frontend/build/web server/static

# Step 3: Build Docker image
echo ""
echo "3. Building Docker image..."
cd server
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME
cd ..

# Step 4: Deploy to Cloud Run
echo ""
echo "4. Deploying to Cloud Run..."

# Create env vars YAML file (handles JSON with special chars)
cat > /tmp/env.yaml << ENVEOF
TMDB_API_KEY: "$TMDB_API_KEY"
FIREBASE_PROJECT_ID: "$PROJECT_ID"
FIREBASE_SERVICE_ACCOUNT: '$FIREBASE_SERVICE_ACCOUNT'
ENVEOF

gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --env-vars-file /tmp/env.yaml

rm /tmp/env.yaml

echo ""
echo "=== Deployment complete! ==="
gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.url)'
