package auth_test

import (
	"bytes"
	"io"
	"io/ioutil"
	"net/http"
	"net/http/httptest"

	"github.com/concourse/concourse/atc/api/accessor"
	"github.com/concourse/concourse/atc/api/accessor/accessorfakes"
	"github.com/concourse/concourse/atc/api/auth"
	"github.com/concourse/concourse/atc/api/auth/authfakes"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("CheckAuthenticationHandler", func() {
	var (
		fakeAccessor *accessorfakes.FakeAccessFactory
		fakeRejector *authfakes.FakeRejector
		fakeaccess   *accessorfakes.FakeAccess

		server *httptest.Server
		client *http.Client
	)

	simpleHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		buffer := bytes.NewBufferString("simple ")

		io.Copy(w, buffer)
		io.Copy(w, r.Body)
	})

	BeforeEach(func() {
		fakeAccessor = new(accessorfakes.FakeAccessFactory)
		fakeaccess = new(accessorfakes.FakeAccess)
		fakeRejector = new(authfakes.FakeRejector)

		fakeRejector.UnauthorizedStub = func(w http.ResponseWriter, r *http.Request) {
			http.Error(w, "nope", http.StatusUnauthorized)
		}

		server = httptest.NewServer(accessor.NewHandler(auth.CheckAuthenticationHandler(
			simpleHandler,
			fakeRejector,
		), fakeAccessor,
			"some-action",
		))

		client = &http.Client{
			Transport: &http.Transport{},
		}
	})

	JustBeforeEach(func() {
		fakeAccessor.CreateReturns(fakeaccess)
	})

	Context("when a request is made", func() {
		var request *http.Request
		var response *http.Response

		BeforeEach(func() {
			var err error

			request, err = http.NewRequest("GET", server.URL, bytes.NewBufferString("hello"))
			Expect(err).NotTo(HaveOccurred())
		})

		JustBeforeEach(func() {
			var err error

			response, err = client.Do(request)
			Expect(err).NotTo(HaveOccurred())
		})

		Context("when the user is authenticated ", func() {
			BeforeEach(func() {
				fakeaccess.IsAuthenticatedReturns(true)
			})

			It("returns 200", func() {
				Expect(response.StatusCode).To(Equal(http.StatusOK))
			})

			It("proxies to the handler", func() {
				responseBody, err := ioutil.ReadAll(response.Body)
				Expect(err).NotTo(HaveOccurred())
				Expect(string(responseBody)).To(Equal("simple hello"))
			})
		})

		Context("when the user is not authenticated", func() {
			BeforeEach(func() {
				fakeaccess.IsAuthenticatedReturns(false)
			})

			It("rejects the request", func() {
				Expect(response.StatusCode).To(Equal(http.StatusUnauthorized))
				responseBody, err := ioutil.ReadAll(response.Body)
				Expect(err).NotTo(HaveOccurred())
				Expect(string(responseBody)).To(Equal("nope\n"))
			})
		})
	})
})
