#!/bin/bash
# Example: Custom Message Filtering
# This shows how to modify voiceaprs-process-message.sh to filter messages

NODE_NUMBER="604011"
MY_CALLSIGN="KI9NG-10"
APRS_PASSCODE="18149"

read -r line

if echo "$line" | grep -q "::"; then
   SENDER=$(echo "$line" | sed -n 's/.*\] \([^>]*\)>.*/\1/p')
   TOCALL=$(echo "$line" | sed -n 's/.*::\([^ ]*\) *.*/\1/p' | sed 's/ *$//')
   MESSAGE=$(echo "$line" | sed -n 's/.*::[^:]*:\([^{]*\).*/\1/p' | sed 's/^ *//' | sed 's/ *$//')
   MSG_ID=$(echo "$line" | sed -n 's/.*{\([0-9A-Za-z]\+\).*/\1/p')
   
   if [ "$TOCALL" = "$MY_CALLSIGN" ]; then
   
      # EXAMPLE FILTERS - Uncomment and customize as needed:
      
      # 1. Ignore messages from specific callsigns
      #if [[ "$SENDER" == "SPAM-CALL" ]]; then
      #   exit 0
      #fi
      
      # 2. Ignore messages containing certain words
      #if echo "$MESSAGE" | grep -qi "spam\|advertisement"; then
      #   echo "$(date): Filtered spam from $SENDER: $MESSAGE" >> /var/log/voiceaprs-filtered.log
      #   exit 0
      #fi
      
      # 3. Only accept messages from a whitelist
      #ALLOWED_CALLS=("KI9NG-5" "N0CALL-1" "W1ABC-7")
      #if [[ ! " ${ALLOWED_CALLS[@]} " =~ " ${SENDER} " ]]; then
      #   exit 0
      #fi
      
      # 4. Ignore messages during certain hours (e.g., nighttime)
      #HOUR=$(date +%H)
      #if [ "$HOUR" -ge 22 ] || [ "$HOUR" -lt 7 ]; then
      #   # Log but don't speak between 10 PM and 7 AM
      #   echo "$(date): Quiet hours - From $SENDER: $MESSAGE" >> /var/log/voiceaprs-messages.log
      #   # Still send ACK
      #   if [ -n "$MSG_ID" ]; then
      #      ACK_MSG="ack${MSG_ID}"
      #      /usr/local/bin/voiceaprs-send-ack.sh "$MY_CALLSIGN" "$APRS_PASSCODE" "$SENDER" "$ACK_MSG" >> /var/log/voiceaprs-messages.log 2>&1
      #   fi
      #   exit 0
      #fi
      
      # 5. Different handling based on message content
      #if echo "$MESSAGE" | grep -qi "^emergency\|^911\|^help"; then
      #   # Play urgent tone before message
      #   SENDER_SPACED=$(echo "$SENDER" | sed 's/\(.\)/\1 /g' | sed 's/ $//')
      #   TEXT="Urgent message from ${SENDER_SPACED}. ${MESSAGE}"
      #else
      #   SENDER_SPACED=$(echo "$SENDER" | sed 's/\(.\)/\1 /g' | sed 's/ $//')
      #   TEXT="A P R S message from ${SENDER_SPACED}. ${MESSAGE}"
      #fi
      
      echo "$(date): From $SENDER: $MESSAGE (ID: $MSG_ID)" >> /var/log/voiceaprs-messages.log
      
      if [ -n "$MSG_ID" ]; then
         ACK_MSG="ack${MSG_ID}"
         /usr/local/bin/voiceaprs-send-ack.sh "$MY_CALLSIGN" "$APRS_PASSCODE" "$SENDER" "$ACK_MSG" >> /var/log/voiceaprs-messages.log 2>&1
         echo "$(date): Sent ACK to $SENDER for message $MSG_ID" >> /var/log/voiceaprs-messages.log
      fi
      
      SENDER_SPACED=$(echo "$SENDER" | sed 's/\(.\)/\1 /g' | sed 's/ $//')
      TEXT="A P R S message from ${SENDER_SPACED}. ${MESSAGE}"
      sudo /usr/bin/asl-tts -n "$NODE_NUMBER" -t "$TEXT" 2>&1 | logger -t voiceaprs
   fi
fi
