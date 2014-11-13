// Define Lock States
const LOCKED = 1;
const UNLOCKED = 2;

// Define Inputs and Outputs
button <- hardware.pin1;
buzzer <- hardware.pin7;

function goToSleep() {
    // reconfigure buzzer to turn it off
    buzzer.configure(DIGITAL_OUT, 0);
    
    // reconfigure out button pin to wakeup
    button.configure(DIGITAL_IN_WAKEUP);
    
    // go to sleep because we're lazy!
    imp.onidle(function() { server.sleepfor(3600); });
}

function checkAlarm() {
    // request alarm state
    agent.send("checkAlarm", null);    

    // reconfigure the button to make it go to sleep
    button.configure(DIGITAL_IN_PULLDOWN, function() {
        // "debounce"
        imp.sleep(0.05);
        
        // read the button
        local state = button.read();
        
        // if the lid is closed
        if (state == 0) {
            // go back to sleep
            goToSleep();            
        }
    });
    
}

// when the agent responds to the "checkAlarm" message
agent.on("checkAlarm", function(state) {
    // check if the lid is open and the lock is set
    if(state == LOCKED && button.read() == 1) {
        // turn on the buzzer
        buzzer.configure(PWM_OUT, 1.0/1000.0, 1.0);
    }
});

// When we wake up
if (hardware.wakereason() == WAKEREASON_PIN) {
    // if we woke up from the lid being opened
    checkAlarm();
} else {
    // if we woke up because because an hour passed, go back to sleep
    goToSleep();
}

