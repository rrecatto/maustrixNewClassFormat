/*
 Serial Read

Read Serial value from Monitor abd set LED leve from that

TODOs:
1. check which pins are digital ins (what logic do they use 3.3V or 5V)
2. write housekeeping codes to start the arduino beginning of a session
3. house keepiung to stop it end of session
4. write code that will send in bytes to arduino
5. make sure triggering works
*/

int LED1 = 9;           // the pin that the LED1 is attached to

int Byte1 = 0;

int trigger1Pin = 7;

// the setup routine runs once when you press reset:
void setup() {
  pinMode(LED1, OUTPUT);
  pinMode(trigger1Pin, INPUT);
  Serial.begin(9600);
}

void loop() {
  // send data only when you receive data:
 
  if (Serial.available() > 0) {
    // incoming data always happens in 2 bytes at a time
    Byte1 = Serial.read();
  }

  if (digitalRead(trigger1Pin)) {
    analogWrite(LED1, Byte1);
  }
  else {
    analogWrite(LED1, 0);
  }