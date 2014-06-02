require_relative 'solitaire.rb'

deck_of_cards = Deck.new

m1 = Message.new("ABVAW LWZSY OORYK DUPVH")
keystream = deck_of_cards.keystream(m1.length)
dec = m1.decrypt(keystream)
puts dec

new_deck = Deck.new
m2 = Message.new("Hey, king!")
m2.display
keystream2 = new_deck.keystream(m2.length)

m3 = Message.new(m2.encrypt(keystream2))
m3.display
m4 = Message.new(m3.decrypt(keystream2))
m4.display