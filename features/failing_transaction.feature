Feature: Failing a transaction

  Background:
    Given I have "go" command installed
    When I run `go build -o bin/dredd-hooks-go github.com/snikch/goodman/bin`
    And I have "dredd" command installed
    And a file named "server.rb" with:
      """
      require 'sinatra'
      get '/message' do
        "Hello World!\n\n"
      end
      """

    And a file named "apiary.apib" with:
      """
      # My Api
      ## GET /message
      + Response 200 (text/html;charset=utf-8)
          Hello World!
      """

  @debug
  Scenario:
    Given a file named "hookfile.go" with:
      """
      package main
      import (
        "fmt"

        "github.com/snikch/goodman/hooks"
        trans "github.com/snikch/goodman/transaction"
      )

      func main() {
          h := hooks.NewHooks()
          server := hooks.NewServer(h)
          h.Before("/message > GET", func(t *trans.Transaction) {
              t.Fail = "Yay! Failed!"
              fmt.Println("Yay! Failed!")
          })
          server.Serve()
          defer server.Listener.Close()
        }
      """
    When I run `go build -o aruba github.com/snikch/goodman/tmp/aruba`
    When I run `../../node_modules/.bin/dredd ./apiary.apib http://localhost:4567 --server "ruby server.rb" --language bin/dredd-hooks-go --hookfiles ./aruba`
    Then the exit status should be 1
    And the output should contain:
      """
      Yay! Failed!
      """
