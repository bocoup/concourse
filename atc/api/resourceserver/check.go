package resourceserver

import (
	"encoding/json"
	"net/http"

	"code.cloudfoundry.org/lager"
	"github.com/concourse/concourse/atc"
	"github.com/concourse/concourse/atc/db"
	"github.com/concourse/concourse/atc/resource"
	"github.com/google/jsonapi"
	"github.com/tedsuo/rata"
)

func (s *Server) CheckResource(dbPipeline db.Pipeline) http.Handler {
	logger := s.logger.Session("check-resource")

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		resourceName := rata.Param(r, "resource_name")

		var reqBody atc.CheckRequestBody
		err := json.NewDecoder(r.Body).Decode(&reqBody)
		if err != nil {
			logger.Info("malformed-request", lager.Data{"error": err.Error()})
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		fromVersion := reqBody.From
		if fromVersion == nil {
			resource, found, err := dbPipeline.Resource(resourceName)
			if err != nil {
				logger.Error("failed-to-get-resource", err, lager.Data{"resource-name": resourceName})
				w.WriteHeader(http.StatusInternalServerError)
				w.Write([]byte(err.Error()))
				return
			}
			if !found {
				logger.Info("resource-not-found", lager.Data{"resource-name": resourceName})
				w.WriteHeader(http.StatusNotFound)
				return
			}

			resourceConfigId := resource.ResourceConfigID()
			resourceConfig, found, err := s.resourceConfigFactory.FindResourceConfigByID(resourceConfigId)
			if err != nil {
				logger.Error("failed-to-get-resource-config", err, lager.Data{"resource-config-id": resourceConfigId})
				w.WriteHeader(http.StatusInternalServerError)
				w.Write([]byte(err.Error()))
				return
			}

			if found {
				latestVersion, found, err := resourceConfig.LatestVersion()
				if err != nil {
					logger.Error("failed-to-get-latest-resource-version", err, lager.Data{"resource-config-id": resourceConfigId})
					w.WriteHeader(http.StatusInternalServerError)
					w.Write([]byte(err.Error()))
					return
				}

				if found {
					fromVersion = atc.Version(latestVersion.Version())
				}
			}
		}

		scanner := s.scannerFactory.NewResourceScanner(dbPipeline)

		err = scanner.ScanFromVersion(logger, resourceName, fromVersion)
		switch scanErr := err.(type) {
		case resource.ErrResourceScriptFailed:
			checkResponseBody := atc.CheckResponseBody{
				ExitStatus: scanErr.ExitStatus,
				Stderr:     scanErr.Stderr,
			}

			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusBadRequest)
			err = json.NewEncoder(w).Encode(checkResponseBody)
			if err != nil {
				logger.Error("failed-to-encode-check-response-body", err)
				w.WriteHeader(http.StatusInternalServerError)
				w.Write([]byte(err.Error()))
			}
		case db.ResourceNotFoundError:
			w.WriteHeader(http.StatusNotFound)
		case db.ResourceTypeNotFoundError:
			w.Header().Set("Content-Type", jsonapi.MediaType)
			w.WriteHeader(http.StatusBadRequest)
			jsonapi.MarshalErrors(w, []*jsonapi.ErrorObject{{
				Title:  "Resource Type Not Found Error",
				Detail: err.Error(),
				Status: "400",
			}})
		case error:
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte(err.Error()))
		default:
			w.WriteHeader(http.StatusOK)
		}
	})
}
