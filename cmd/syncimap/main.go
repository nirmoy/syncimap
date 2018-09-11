package main

import (
	"log"
	"crypto/tls"

	"github.com/emersion/go-imap/client"
	"github.com/emersion/go-imap"
	"github.com/rthornton128/goncurses"
)


func print_email(menu_items []string) {
	stdscr, err := goncurses.Init()
	if err != nil {
		log.Fatal("init:", err)
	}
	defer goncurses.End()

	goncurses.Raw(true)
	goncurses.Echo(false)
	goncurses.Cursor(0)
	stdscr.Clear()
	stdscr.Keypad(true)

	items := make([]*goncurses.MenuItem, len(menu_items))
	for i, val := range menu_items {
		items[i], _ = goncurses.NewItem("", val)
		defer items[i].Free()
	}

	menu, err := goncurses.NewMenu(items)
	if err != nil {
		stdscr.Print(err)
		return
	}
	defer menu.Free()

	menu.Post()

	stdscr.MovePrint(20, 0, "'q' to exit")
	stdscr.Refresh()

	for {
		goncurses.Update()
		ch := stdscr.GetChar()

		switch goncurses.KeyString(ch) {
		case "q":
			return
		case "down":
			menu.Driver(goncurses.REQ_DOWN)
		case "up":
			menu.Driver(goncurses.REQ_UP)
		}
	}
}
func main() {
	log.Println("Connecting to server...")
	tlsConfig := &tls.Config{ServerName: "imap.suse.de", InsecureSkipVerify: true,}
	// Connect to server
	c, err := client.DialTLS("imap.suse.de:993", tlsConfig)
	if err != nil {
		log.Fatal(err)
	}
	log.Println("Connected")

	// Don't forget to logout
	defer c.Logout()

	log.Println("TLS started")

	// Login
	if err := c.Login("ndas", "@!l@B!@3"); err != nil {
		log.Fatal(err)
	}
	log.Println("Logged in")

	// List mailboxes
	mailboxes := make(chan *imap.MailboxInfo, 10)
	done := make(chan error, 1)
	go func () {
		done <- c.List("", "*", mailboxes)
	}()

	log.Println("Mailboxes:")
	for m := range mailboxes {
		log.Println("* " + m.Name)
	}

	if err := <-done; err != nil {
		log.Fatal(err)
	}

	// Select INBOX
	mbox, err := c.Select("INBOX/mailing_lists/openvpn", false)
	if err != nil {
		log.Fatal(err)
	}
	log.Println("Flags for INBOX:", mbox.Flags)

	// Get the last 4 messages
	from := uint32(2)
	to := mbox.Messages
	if mbox.Messages > 3 {
		// We're using unsigned integers here, only substract if the result is > 0
		from = mbox.Messages - 3
	}
	seqset := new(imap.SeqSet)
	seqset.AddRange(from, to)

	messages := make(chan *imap.Message, 2)
	done = make(chan error, 1)
	go func() {
		done <- c.Fetch(seqset, []imap.FetchItem{imap.FetchEnvelope}, messages)
	}()
	log.Println("Last 4 messages:")
	emails := []string{""}
	for msg := range messages {
		emails = append(emails, msg.Envelope.Subject)
	}
	elements := []string{"cat", "dog", "bird"}
	log.Println(emails)
	log.Println(elements)
	print_email(emails)
	if err := <-done; err != nil {
		log.Fatal(err)
	}

	log.Println("Done!")
}
