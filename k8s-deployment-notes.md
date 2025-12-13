# Odilia Kubernetes Deployment - Quick Reference

## Deployed On
- Date: $(date)
- Cluster: Minikube
- Namespace: odilia-mcdonalds

## Access URLs
- Application: $(minikube service frontend -n odilia-mcdonalds --url)
- NodePort: http://$(minikube ip):30080

## Services
- frontend (yelb-ui)
- appserver (yelb-appserver)
- redis-master (redis-server)
- postgres-master (yelb-db)

## Important Service Names
The application expects these exact service names:
- yelb-appserver (for frontend)
- redis-server (for appserver)
- yelb-db (for appserver)

## Quick Commands
```bash
# View all resources
kubectl get all -n odilia-mcdonalds

# Check logs
kubectl logs -f deployment/frontend -n odilia-mcdonalds

# Scale
kubectl scale deployment frontend --replicas=3 -n odilia-mcdonalds

# Access application
minikube service frontend -n odilia-mcdonalds

# Connect to database
kubectl exec -it deployment/postgres-master -n odilia-mcdonalds -- psql -U postgres -d yelbdatabase

# Connect to Redis
kubectl exec -it deployment/redis-master -n odilia-mcdonalds -- redis-cli

# Delete everything
kubectl delete namespace odilia-mcdonalds
```

## Deployment Files
- k8s-storage.yaml (PVCs)
- k8s-stateful.yaml (Deployments with storage)
- deploy-to-k8s.sh (Deployment script)

## Notes
- Successfully deployed on Minikube
- Frontend was crashing due to missing yelb-appserver service
- Fixed by creating service with correct name
- All components now running and functional
