require 'rspec/matchers'
require 'howitzer/utils/email/mail_client'

class Email
  include RSpec::Matchers
  attr_reader :recipient_address

  def initialize(message)
    expect(message.subject).to include(self.class::SUBJECT)
    @recipient_address = ::Mail::Address.new(message.to.first)
    @message = message
  end

  def self.find_by_recipient(recipient)
    find(recipient, self::SUBJECT)
  end

  def self.find(recipient, subject)
    messages = MailClient.by_email(recipient).find_mail do |mail|
      /#{Regexp.escape(subject)}/ === mail.subject && mail.to == [recipient]
    end

    if messages.first.nil?
      log.error "#{self} was not found (recipient: '#{recipient}')"
      return   # TODO check log.error raises error
    end
    new(messages.first)
  end

  def plain_text_body
    get_mime_part(@message, 'text/plain').to_s
  end

  def get_mime_part(part, type)
    return part.body if part["content-type"].to_s =~ %r!#{type}!
    # Recurse the multi-parts
    part.parts.each do |sub_part|
      r = get_mime_part(sub_part, type)
      return r if r
    end
    nil
  end

  protected :get_mime_part

end