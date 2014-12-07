require 'net/smtp'

def send_mail(user, pass, from_addr, to_addrs, subject, body)
  content = <<CONTENT
Date: #{Time::now.strftime("%a, %d %b %Y %X")}
From: #{from_addr}
To: #{to_addrs.join(',')}
Subject: #{subject}
Mime-Version: 1.0
Content-Type: text/plain; charset=utf-8

#{body}
CONTENT

  smtp = Net::SMTP.new('smtp.gmail.com', 587)
  smtp.enable_starttls
  smtp.start('localhost.localdomain', user, pass, :plain) do |connection|
    connection.send_mail(content, from_addr, *to_addrs)
  end
end
