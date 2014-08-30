require 'nokogiri'
require 'curb'

def login(username, password)
	c = Curl::Easy.new("https://mobile.twitter.com/session/new")
	c.ssl_verify_peer = false
	c.perform
	response = c.body_str
	doc = Nokogiri::XML(response)
	span = doc.css('span.m2-auth-token').to_s
	auth = (/value="(.*)"/.match(span))[1]
	headers = c.header_str
	cookies = headers.scan(/^Set-Cookie:\s*([^;]*)/mi)
	cookie = cookies.join(";")

	http = Curl.post("https://mobile.twitter.com/session", {:authenticity_token => auth,
															:username => username,
															:password => password,
															:commit => "Sign+in"}) do|http|
		http.headers['Cookie'] = cookie
		http.ssl_verify_peer = false
	end
	headers2 = http.header_str
	cookies2 = headers2.scan(/^Set-Cookie:\s*([^;]*)/mi)
	cookie2 = cookies2.join(";")
	return cookie2 + ":" + auth
end

def follow(cookie, auth, user)
	http = Curl.post("https://mobile.twitter.com/" + user + "/follow", {:authenticity_token => auth,
																		:commit => "Follow"}) do|http|
		http.headers['Cookie'] = cookie
		http.ssl_verify_peer = false
	end
	res = http.body_str
end

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def green(text); colorize(text, 32); end
def red(text); colorize(text, 31); end

doc = IO.read('file.txt')
content = doc.split("\n")

#counter
success = 0
fail = 0

for item in content

	#bikin array
	datfx = item.split(":")
	user = datfx[0]
	pass = datfx[1]
	
	#mulai login
	creds = login(user, pass)
	
	#ambil response
	datax = creds.split(":")
	cookie = datax[0]
	auth = datax[1]
	if cookie.scan(/auth_token/).length == 0
		fail += 1
		puts user + " - " + red("Fail")
	else
		success += 1
		follow(cookie, auth, "Twitter")
		puts user + " - " + green("Success")
	end
end
puts fail.to_s + " Fail & " + success.to_s + " Success"