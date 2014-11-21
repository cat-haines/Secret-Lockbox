/******************** Constants ********************/
// Your MailGun settings
const API_KEY = "key-a1b2c3...";
const SUBDOMAIN = "sandbox123abc.mailgun.org";

// Define what email to notify
const EMAIL = "you@example.com";

// Define your password for the lockbox
const PASSWORD = "yourpassword"

// Define Lock States
const UNLOCKED = 0;
const LOCKED = 1;

/******************** HTML CODE ********************/
const html = @"
<!DOCTYPE html>
<html lang='en'>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <link rel='shortcut icon' href='http://www.freefavicon.com/freefavicons/objects/love-kills-152-173204.png' />
    
    <title>My Lockbox</title>
    
    <link rel='stylesheet' href='https://maxcdn.bootstrapcdn.com/font-awesome/4.2.0/css/font-awesome.min.css'>
	<link rel='stylesheet' href='https://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css'>
	<style> 
	    .webpage {
	        /* Background colour */
	        background-color: white;
	        
	        /* Full screen background image */
	        background-image: url('http://www.wallpaperdisk.com/wallpapers/Space/space2.jpg');
	        
            /* tiled background image */
            /*
             * background-image: url('http://zho.berka.com/tiles/starsandnebula250d.jpg');
	         * background-repeat: repeat;
	         */
	    }
	    
	    .title {
	        color: white;
	    }
	    
	    .password-box {
	        width: 80%;
	        margin: 25px auto 25px auto;
	        text-align:center;
	        
	        border-color: black;
	        background-color: white;
	        color: black;
	    }
	    
	    .btn {
	        width: 150px;
	        
	        border-color: grey;
	        background-color: white;
	        color: black;
	    }
	    
	    .lock-icon {
	        margin-top: 20px;
	        color: white;
	    }
	    
        .footer {
           position:fixed;
           left:0px;
           bottom:0px;
           height:30px;
           width:100%;
        }

    </style>
  </head>
  <body class='webpage'>
	<div class='container col-xs-12 col-sm-4 col-sm-offset-4 text-center'>
	  <h1 class='title'>My Lockbox</h1>
  	    <input class='form-control password-box' type='password'  id='pw' placeholder='Password'>
  	    
	    <button class='btn' type='button' onclick='lock();'><i class='fa fa-lock'></i>&nbsp; Lock</button>
        <button class='btn' type='button' onclick='unlock();'><i class='fa fa-unlock-alt'></i>&nbsp; Unlock</button>

      <div class='lock-icon'>
        <i class='fa fa-question fa-5x' id='status'></i>
      </div>
      
      <div class='footer'>
        Powered by <a href='http://electricimp.com' target='_blank'>Electric Imp</a>
      </div>
    <script src='https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js'></script>
    <script src='https://netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js'></script>
    <script>
        var myUrl = window.location.href;
        
        function lock() {
            var pw = $('#pw').val();
            var lockUrl = myUrl + '/lock';
            
            $.post(lockUrl, pw, function(state) {
                setLockIcon(state);
            });
        }
        
        function unlock() {
            var pw = $('#pw').val();
            var unlockUrl = myUrl + '/unlock';
            
            $.post(unlockUrl, pw, function(state) {
                setLockIcon(state);
            });
        }
        
        function getStatus() {
            // fetch the current state from the agent
            var statusUrl = myUrl + '/status';
            
            // set the lock icon based on the result
            $.get(statusUrl, function(d) {
                setLockIcon(d);
            });
        }
        
        
        function setLockIcon(state) {
            // remove all the classes that set the image
            $('#status').removeClass('fa-question');
            $('#status').removeClass('fa-lock');
            $('#status').removeClass('fa-unlock-alt');
            
            // add the proper images based on the state
            if (state == 0) {
                $('#status').addClass('fa-unlock-alt');
            }
            if (state == 1) {
                $('#status').addClass('fa-lock');
            }
        }

        // when the webpage is loaded
        $(function() {
            getStatus();
        });
    </script>
  </body>
</html>
"


/******************** LIBRARY CODE ********************/
function SendEmail(to, subject, text) {
    local url = "https://api.mailgun.net/v2/" + SUBDOMAIN + "/messages";
    local fromEmail = "alarm@" + SUBDOMAIN;
 
    local headers = { "Authorization": "Basic " + http.base64encode("api:" + API_KEY) };
    
    local data = http.urlencode({
        to = to,
        from = fromEmail, 
        subject = subject,
        text = text
    });
    
    http.post(url, headers, data).sendasync(function(resp) {
        if (resp.statuscode != 200 && resp.statuscode != 0) {
            server.log(resp.statuscode + " - " + resp.body);
        }
    });
}
 
/******************** Electric Imp CODE ********************/
// Create a variable to hold the current lock state
lockStatus <- LOCKED;

// agent code:
function httpHandler(request, response) {
    try {
        
        // webpage
        if (request.path == "/") {
            response.send(200, html);
            return;
        }
        
        // get the current status
        if (request.path == "/status") {
            response.send(200, lockStatus);
            return;
        }
        
        // Lock command
        if (request.path == "/lock") {
            // check the password
            if (request.body == PASSWORD) {
                // change the lockStatus to LOCKED if password is ok
                lockStatus = LOCKED;
            }
        }

        // unlock command
        if (request.path == "/unlock") {
            // check the password
            if (request.body == PASSWORD) {
                // change the lockStatus to UNLOCKED if password is ok
                lockStatus = UNLOCKED;
            }
        }

        // send back a response with the current lock status
        response.send(200, lockStatus);
    } catch (ex) {
        // if there was an error
        response.send(500, "ERROR - " + ex);
        return;
    }
}

// run httpHandler whenever a request comes into the Agent URL
http.onrequest(httpHandler);

// when the alarm is triggered, run this code
function ALARM() {
    server.log("ALARM ALARM ALARM");
    SendEmail(EMAIL, "ALARM! ALARM!", "Someone just tried to open your lockbox without unlocking it!");
}

// when we get a checkAlarm message from the device
device.on("checkAlarm", function(data) {
    // send them our current lockStatus
    device.send("checkAlarm", lockStatus);
    // if it's locked, trigger the alarm!
    if (lockStatus == LOCKED) {
        ALARM();
    }
});
