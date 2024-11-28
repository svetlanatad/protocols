# Universal Downloader 

# Introduction
Draft: This project aims to create a universal downloader, that is able to download nex, spartan, gemini and htpp which we will be able to implement with 
(**there is a way to show them? inky said **)

data transfer protocol, otherwise, communication protocol, which is a set of logical lever interface rules that enables the exchange between programs. These rules enable data exchange between devices or systems. They also define how data is being formatted, transmitted, and received, while ensuring that devices communicate effectively despite  differences in hardware, software, or network infrastructure. Most common communication protocol we all know is http, another one that is even more common, https, or TCP/IP for internet connectivity.   

The importance of this project is to help the people around us who need to download files from less common communication protocols, as we are all able to easily access and download files that we need for our daily use or sense of happiness from https with a variety of choice of browsers, and since I intend to extend the project into a fully functional and efficient gemini browser one day, I hope to make some people happy with the idea and the implementation of the project. 


# What do we need for a universal downloader?
Well, first of all, we need to research and learn about communication protocols, what they are exactly, and how to work with them. Let us dive in, as Michael Mozz, the creator of Spartan says, let us dive in into exploring the topics. I will try my best to convey the knowledge I obtained to the reader as much as possible.
-------------------------------------------------------------------------------


Now that we know that to be able to establish a connection, we need to have something that the connection is between in. We don't use connection without specifying, between what and what, most of the time, right? This is when we need to understand the concept of a client, and a server.


A client is a computer or device that requests services or resources from a server, while a server is a computer or device that provides services or resources to clients. Clients initiate communication with servers by sending requests, and servers respond to these requests by providing the requested services or resources. In essence, clients are the consumers of services, while servers are the providers. Both clients and servers are essential components of a client-server architecture, which allows for efficient and scalable communication between multiple devices on a network. 
In this case, we need a server and a client to work on, to be able to download, or a term I would prefer to use, to read bytes from. We decided to use Michael Lazar's spartan server and client model that is written in python, and we decided to implement the client and the server, and everything else, in our favorite programming language, Oberon, and why using Oberon is a good choice, the reader may find in section #####.  


server? 



client? 



In that case, if we develop the server and the client,  what do we need to read bytes from? A data structure. What is the most efficient data structure to read bytes from? To be frank, I don't know, but we decided to use a dynamic array. I ended up spending a week to write an entire module dedicated to dynamic array structure, which works in the following way:

dynamic array? 




So, we end up using a buffer which is  a dynamic array to be able to read and write  bytes from servers, at this point, eventually, we will be able to download files as well. But, how does downloading work exactly? 




download? 





Hence, we created this tool, of course, the tool, the dynamic array module, and any other available module that we implemented is open source and hopefully useful for people, I plan to extend the project and one day hopefully I will implement a gemini client browser.  

END
section references
section appendix
section thank you 










--------------------------------------------------------------------------------
# Difference between spartan and gemini servers 
spartan:// is a client-to-server protocol designed for hobbyists. Spartan draws on ideas from gemini, gopher, and http to create something new, yet familiar. It strives to be simple, fun, and inspiring.

Spartan sends ASCII-encoded, plaintext requests over TCP. Arbitrary text and binary files are supported for both upload and download. Like gemini, the default hypertext document in spartan is text/gemini. A special line type ("=:") is used to prompt for input. Spartan has four status codes: "success", "redirect", "server error", and "client error".
Gemini is an application-layer internet communication protocol for accessing remote documents, similar to HTTP and Gopher. It comes with a special document format, commonly referred to as "gemtext", which allows linking to other documents. Started by a pseudonymous person known as Solderpunk, the protocol is being finalized collaboratively and as of October 2022, has not been submitted to the IETF organization for standardization. 
#   Requests 
#   Spartan Request
A spartan request is a single ASCII-encoded request line followed by an optional data block.

request      = request-line [data-block]
request-line = host SP path-absolute SP content-length CRLF


The host component specifies the host of the server that the request is being sent to. The port number should not be included in the host component. Hosts that contain non-ASCII characters (IDNs) should be converted to punycode.

The path component specifies the resource that is being requested. It must be absolute and begin with a "/" character.

The data block can be used by the client to upload arbitrary data to the server. The content-length component specifies the length, in bytes, of the data block. A content length of "0" means that no extra data will be attached to the request.

The format of uploaded data is left up to the server to define based on surrounding context. It might contain plain text, binary data, or a mixed encoding.

# Gemini Request
The client connects to the server and sends a request which consists of an absolute URI followed by a CR (character 13) and LF (character 10). The augmented BNF [STD68] for this is:

	request = absolute-URI CRLF

	; absolute-URI from [STD66]
	; CRLF         from [STD68]

When making a request, the URI MUST NOT exceed 1024 bytes, and a server MUST reject requests where the URI exceeds this limit. A server MUST reject a request with a userinfo portion. Clients MUST NOT send a fragment as part of the request, and a server MUST reject such requests as well. If a client is making a request with an empty path, the client SHOULD add a trailing '/' to the request, but a server MUST be able to deal with an empty path. 

# Responses
# Spartan

A spartan response is single ASCII-encoded status line followed by an optional response body.

Spartan responses use single-digit status codes to indicate success or failure.

reply             = success / redirect / client-error / server-error

success           = '2' SP mimetype      CRLF body
redirect          = '3' SP path-absolute CRLF
client-error      = '4' SP errormsg      CRLF
server-error      = '5' SP errormsg      CRLF

# Gemini 

Upon receiving a request, the server will send back a response header. In the case of a successful request, the header is followed by the content requested by the client. Response headers MUST be UTF-8 encoded text and MUST NOT begin with the Byte Order Mark U+FEFF. A response header consists of a two digit status code, possibly followed some additional information (which depends upon the response being sent), always followed by a CR and LF. The augmented BNF:

        reply    = input / success / redirect / tempfail / permfail / auth

        input    = "1" DIGIT SP prompt        CRLF
        success  = "2" DIGIT SP mimetype      CRLF body
        redirect = "3" DIGIT SP URI-reference CRLF
                        ; NOTE: [STD66] allows "" as a valid
                        ;       URI-reference.  This is not intended to
                        ;       be valid for cases of redirection.
        tempfail = "4" DIGIT [SP errormsg]    CRLF
        permfail = "5" DIGIT [SP errormsg]    CRLF
        auth     = "6" DIGIT [SP errormsg]    CRLF

        prompt   = 1*(SP / VCHAR)
        mimetype = type "/" subtype *(";" parameter)
        errormsg = 1*(SP / VCHAR)
        body     = *OCTET

        VCHAR    =/ UTF8-2v / UTF8-3 / UTF8-4
        UTF8-2v  = %xC2 %xA0-BF UTF8-tail ; no C1 control set
                 / %xC3-DF UTF8-tail

	; URI-reference from [STD66]
	;
	; type          from [RFC2045]
	; subtype       from [RFC2045]
	; parameter     from [RFC2045]
	;
	; CRLF          from [STD68]
	; DIGIT         from [STD68]
	; SP            from [STD68]
	; VCHAR         from [STD68]
	; OCTET         from [STD68]
	; WSP           from [STD68]
	;
	; UTF8-3        from [STD63]
	; UTF8-4        from [STD63]
	; UTF8-tail     from [STD63]

The VCHAR rule from [STD68] is extended to include the non-control codepoints from Unicode (and encoded as UTF-8 [STD63]).

The body is unspecified here, as the contents depend upon the MIME type of the content being served. However, when the MIME type of the content is any subset of "text" (including "text/gemini") and the content has been encoded with any Unicode encoding, the body SHOULD NOT begin with an encoding of the Byte Order Mark U+FEFF. The encoding used, including byte order, should instead be communicated to the client through use of the "charset" parameter in the response header. If a body declared to be of type "text/gemini" begins with a Byte Order Mark, clients SHOULD ignore the mark when parsing the document.

Upon sending the complete response (which may include content), the server closes the connection and MUST use the TLS close_notify mechanism to inform the client that no more data will be sent.

The status values range from 10 to 69 inclusive, although not all values are currently defined. They are grouped such that a client MAY use the initial digit to handle the response, but the additional digit is there to further clarify the status, and it is RECOMMENDED that clients use the additional digit when deciding what to do. Servers MUST NOT send status codes that are not defined. 

