This simple comamnd line tool implements dynamic DNS when using Cloudflare as a DNS provider. This is a personal project, not warantied in any way at all. YMMV. 

## Build and Run

To build the release version:

```sh
swift build --configuration release
```

The tool has two commands:

* `check` checks to see if your current IP matches the DNS configuration
* `refresh` updates the DNS configuration to match your current IP

Both require the same inputs:

1. An environment variable called `CLOUDFLARE_API_TOKEN` set to (…uh) a valid Cloudflare API token.
2. The Cloudflare zone *name*, eg `example.com`
3. The Cloudflare DNS record name, eg `myhouse.example.com`

The tool will discover the public-facing IP address of the machine on which it runs using the [ipify](https://api.ipify.org) service. It reads DNS entries using the Cloudflare API.

Here's an example of the `check` command:

```sh
CLOUDFLARE_API_TOKEN=XXX cfddns check example.com myhouse.example.com
```

And the `refresh` command:

```sh
CLOUDFLARE_API_TOKEN=XXX cfddns refresh example.com myhouse.example.com
```

## Install and Run Periodically

Generally you want to run the `refresh` command periodically (eg, every five minutes).

> Note: You may want to configure your DNS record with a short TTL in Cloudflare as well. I set mine to 5 minutes. This means in the worst case, if your IP address changes, it can take up to ten minutes for the change to be detected, applied, and to completely propagate.

I used these steps to to run it periodically on a home server running macOS 15 (Sequoia):

**1. Create a new non-admin user called `cfddns-runner`.**<br>
I did this in the System Preferences UI for simplicity. Use any password you want for now. We'll remove it later.

**2. Log in as this user once, and then log back out again.**<br>
Again, in the interactive UI. There seem to be some important steps in the first-login flow that need to happen but admittedly I don't really understand what. This account doesn't need iCloud, Siri, etc… so just skip/decline all the offers on first login.

**3. Store the Cloudflare API token for only this user.**<br>
I do this as my usual Admin user on the command line, and make sure only this new user can read the token:
```sh
sudo /bin/sh -c 'printf "YOUR_TOKEN_HERE" > /Users/cfddns-runner/cloudflare-token'
sudo chmod 600 /Users/cfddns-runner/cloudflare-token 
``` 

**4. Create the log file.**<br>
Since the command will run with the permissions of the new user, and I want to log to `/var/log`, I need to pre-create the log file and ensure my user can access it.
```sh
sudo touch /var/log/cfddns.log
sudo chown cfddns-runner /var/log/cfddns.log
sudo chmod 640 /var/log/cfddns.log
```

**5. Install the LaunchDaemon.**<br>
I use this plist file to run the command every 5 minutes, as the `cfddns-runner` user. Since this is a LaunchDaemon, the user does not need to be logged in for this to work.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.gwcoffey.cfddns</string>
    <key>UserName</key>
    <string>cfddns-runner</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>CLOUDFLARE_API_TOKEN=$(cat /Users/cfddns-runner/cloudflare-token | tr -d '\n') /usr/local/bin/cfddns refresh example.com myhouse.example.com</string>
    </array>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>StandardOutPath</key>
    <string>/var/log/cfddns.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/cfddns.log</string>
</dict>
</plist>
```

To install it:

```sh
sudo cp com.gwcoffey.cfddns.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/com.gwcoffey.cfddns.plist
sudo chmod 644 /Library/LaunchDaemons/com.gwcoffey.cfddns.plist
```

And to load it:

```sh
sudo launchctl load /Library/LaunchDaemons/com.gwcoffey.cfddns.plist
```

The command should now run and refresh the IP every five minutes, even when nobody is logged in to the server.

**6. Shore up security on the new user.**<br>
Since I created a limited-permission user for this command to run under, and I never need to log in as that user, I like to make some changes to the user to shore up security.

1. Disable login as this user:
```sh
sudo chsh -s /usr/bin/false cfddns-runner
```

2. Disallow SSH to this user:
```sh
echo "DenyUsers cfddns-runner" | sudo tee -a /etc/ssh/sshd_config
```

3. Hide the user from the macOS login screen:
```sh
sudo dscl . create /Users/cfddns-runner IsHidden 1
```

4. Remove the password as it is no longer relevant:
```sh
sudo dscl . -delete /Users/cfddns-runner Password
``` 
 
After making these changes, you can reboot, or just manually restart the SSH daemon:

```sh
sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
sudo launchctl load /System/Library/LaunchDaemons/ssh.plist
```
