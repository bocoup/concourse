package resourceserver

import (
	"fmt"
	"net/http"

	"code.cloudfoundry.org/lager"
	"github.com/concourse/concourse/atc"
	"github.com/concourse/concourse/atc/creds"
	"github.com/concourse/concourse/atc/db"
	"github.com/tedsuo/rata"
)

// CheckResourceWebHook defines a handler for process a check resource request via an access token.
func (s *Server) CheckResourceWebHook(dbPipeline db.Pipeline) http.Handler {
	logger := s.logger.Session("check-resource-webhook")

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		resourceName := rata.Param(r, "resource_name")
		webhookToken := r.URL.Query().Get("webhook_token")

		if webhookToken == "" {
			logger.Info("no-webhook-token", lager.Data{"error": "missing webhook_token"})
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		pipelineResource, found, err := dbPipeline.Resource(resourceName)
		if err != nil {
			logger.Error("database-error", err, lager.Data{"resource-name": resourceName})
			w.WriteHeader(http.StatusInternalServerError)
			return
		}

		if !found {
			logger.Info("resource-not-found", lager.Data{"error": fmt.Sprintf("Resource not found %s", resourceName)})
			w.WriteHeader(http.StatusNotFound)
			return
		}

		variables := s.variablesFactory.NewVariables(dbPipeline.TeamName(), dbPipeline.Name())
		token, err := creds.NewString(variables, pipelineResource.WebhookToken()).Evaluate()
		if token != webhookToken {
			logger.Info("invalid-token", lager.Data{"error": fmt.Sprintf("invalid token for webhook %s", webhookToken)})
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		var fromVersion atc.Version
		resourceConfigId := pipelineResource.ResourceConfigID()
		resourceConfig, found, err := s.resourceConfigFactory.FindResourceConfigByID(resourceConfigId)
		if err != nil {
			logger.Error("failed-to-get-resource-config", err, lager.Data{"resource-config-id": resourceConfigId})
			w.WriteHeader(http.StatusInternalServerError)
			return
		}

		if found {
			latestVersion, found, err := resourceConfig.LatestVersion()
			if err != nil {
				logger.Error("failed-to-get-latest-resource-version", err, lager.Data{"resource-config-id": resourceConfigId})
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
			if found {
				fromVersion = atc.Version(latestVersion.Version())
			}
		}

		scanner := s.scannerFactory.NewResourceScanner(dbPipeline)
		err = scanner.ScanFromVersion(logger, resourceName, fromVersion)
		switch err.(type) {
		case db.ResourceNotFoundError:
			w.WriteHeader(http.StatusNotFound)
		case error:
			w.WriteHeader(http.StatusInternalServerError)
		default:
			w.WriteHeader(http.StatusOK)
		}
	})
}
