module MailAdapters
  class Abstract

    attr_reader :message

    def self.find(recipient, subject)
      raise NotImplementedError
    end

    ##
    #
    # Creates new email with message
    #
    # *Parameters:*
    # * +message+ - email message
    #

    def initialize(message)
      @message = message
    end

    ##
    #
    # Returns plain text body of email message
    #

    def plain_text_body
      raise NotImplementedError
    end

    ##
    #
    # Returns html body of email message
    #

    def html_body
      raise NotImplementedError
    end

    ##
    #
    # Returns mail text
    #

    def text
      raise NotImplementedError
    end

    ##
    #
    # Returns who has send email data in format: User Name <user@email>
    #

    def mail_from
      raise NotImplementedError
    end

    ##
    #
    # Returns array of recipients who has received current email
    #

    def recipients
      raise NotImplementedError
    end

    ##
    #
    # Returns email received time in format:
    #

    def received_time
      raise NotImplementedError
    end

    ##
    #
    # Returns sender user email
    #

    def sender_email
      raise NotImplementedError
    end

    ##
    #
    # Allows to get email MIME attachment
    #

    def get_mime_part
      raise NotImplementedError
    end
  end
end