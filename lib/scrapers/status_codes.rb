module Scrapers

  #
  # This module keeps all status codes used by the DataMining.
  #
  module StatusCodes

    SUCCESS                       = 100 # Indicates a succeessful action.

    INTERNAL_ERROR                = 300 # Indicates a general internal error.

    MAX_ATTEMPTS_EXCEEDED         = 301 # The maximum number of attempts was exceeded.

    PARAMETERS_BLANK              = 302 # At least one mandatory parameter is blank.

    INVALID_PARAMETERS            = 303 # Invalid parameters were sent.

    SITE_UNAVAILABLE              = 305 # The source site is temporarily unavailable.

    BLOCKED_REQUEST               = 306 # The source site has blocked the request.

    # FIXME: Add case that just needs a new try.
    UNEXPECTED_INCORRECT_RESPONSE = 307 # New type of error, that the scraper needs to learn how to process.

    UNEXPECTED_CORRECT_RESPONSE   = 308 # New type of response, that the scraper needs to learn how to process.

    TRY_AGAIN                     = 309 # Temporary error, a new request should be successful.

    NON_EXISTENT                  = 310 # The data does not exist in the source site's database.

    MULTIPLE_RESULTS              = 311 # There is no single status code that represents the result, because
                                        # the scraper call needed to be split into multiple requests, each
                                        # with its own status code.
  end

end
