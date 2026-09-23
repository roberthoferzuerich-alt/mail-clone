import re

def update_ios():
    try:
        with open('ios/Runner/Info.plist', 'r', encoding='utf-8') as f:
            content = f.read()
            
        permissions = """
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>
	<key>NSCalendarsUsageDescription</key>
	<string>Wir benötigen Zugriff auf den Kalender, um deine lokalen Termine in der App anzuzeigen.</string>
	<key>NSContactsUsageDescription</key>
	<string>Wir benötigen Zugriff auf Kontakte, um Termin-Einladungen zuzuordnen.</string>
"""
        
        content = content.replace("""\t<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>""", permissions.strip())
    
        with open('ios/Runner/Info.plist', 'w', encoding='utf-8') as f:
            f.write(content)
    except FileNotFoundError:
        pass

update_ios()
print("Updated Info.plist")

