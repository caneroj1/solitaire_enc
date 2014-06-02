class Card
	attr_accessor :suite, :rank, :value

	## initialize a card
	# jokers must be distinct for encryption to work
	# to create a joker, pass in suite :joker, rank = 1 for an 'a' joker
	# rank = 2 for a 'b' joker
	def initialize(suite, rank)
		case suite
		when :clubs
			@value, @rank, @suite = rank, rank, suite
		when :diamonds
			@value, @rank, @suite = rank + 13, rank, suite
		when :hearts
			@value, @rank, @suite = rank + 26, rank, suite
		when :spades	
			@value, @rank, @suite = rank + 39, rank, suite
		when :joker
			@value, @rank, @suite = 53, rank, 'a' if rank == 1
			@value, @rank, @suite = 53, rank, 'b' if rank == 2
		end
	end

	## neat little to-string method
	def display
		"SUITE: #{@suite}, RANK: #{@rank}, VALUE: #{@value}"
	end

	## overloaded comparison operator
	def ==(card)
		self.suite == card.suite && self.rank == card.rank && self.value == card.value
	end
end

class Deck

	## initializes a deck of cards that includes jokers
	def initialize
		@deck_of_cards = Array.new
		# generate the unkeyed deck
		(1..52).each do |i|
			case i
			when 1..13
				@deck_of_cards.push(Card.new(:clubs, i))
			when 14..26
				@deck_of_cards.push(Card.new(:diamonds, i - 13))
			when 27..39
				@deck_of_cards.push(Card.new(:hearts, i - 26))
			when 40..52
				@deck_of_cards.push(Card.new(:spades, i - 39))
			end
		end

		# add jokers to the deck
		@deck_of_cards.push(Card.new(:joker, 1))
		@deck_of_cards.push(Card.new(:joker, 2))
	end

	## neat to-string method for the deck
	def display
		@deck_of_cards.each.with_index do |card, i|
			puts "#{i}=> #{card.display}"
		end
	end

	## this method generates a keystream of letters to encrypt a message with
	# if the card is a joker (letter = 53), we skip that card and get a new one to create
	# a letter for the keystream. we want to generate as many keystream letters as there are
	# letters in the message (letter_count)
	def keystream(letter_count)
		keystream = Array.new
		letters_added = 0
		begin 
			letter = get_letter
			if letter != 53 
				keystream << letter
				letters_added += 1
			end
		end while letters_added < letter_count
		keystream
	end

	private

	## this function returns a single letter to be used in the keystream
	# it calls various deck manipulation functions in order to create a secure
	# encryption method
	def get_letter
		# move the 'a' and 'b' jokers 
		move_joker_a
		move_joker_b

		# get their new positons
		new_a = @deck_of_cards.index(Card.new(:joker, 1))
		new_b = @deck_of_cards.index(Card.new(:joker, 2))

		# perform a triple split around the positions of the jokers
		triple_split(new_a, new_b) if new_a < new_b
		triple_split(new_b, new_a) if new_b < new_a

		# perform a count cut with the value of the bottom card
		count_cut(@deck_of_cards[53].value)

		# now that the deck has been properly mutated, we can now
		# get the output lettere by getting the value of the top card in the deck
		# and stepping down that many cards (including the top) and converting
		# the value of the ending card to a letter
		final_val = @deck_of_cards[@deck_of_cards[0].value].value
	end

	## this function moves the 'a' joker around. it moves down one card in the deck.
	def move_joker_a
		# find the index of the 'a' joker
		index_a = @deck_of_cards.index(Card.new(:joker, 1))
		# if the 'a' joker is the last card in the deck, move it below the first card
		if index_a == 53
			joker_a = @deck_of_cards.delete_at(index_a)
			@deck_of_cards.insert(1, joker_a)

			# new position of the 'a' joker
			new_a = 1
		else # swap the 'a' joker with the card right below it
			@deck_of_cards[index_a], @deck_of_cards[index_a + 1] = @deck_of_cards[index_a + 1], @deck_of_cards[index_a] 
			
			# new position of the 'a' joker
			new_a = index_a + 1
		end
	end

	## this function moves the 'b' joker around. it moves the card down two spots in the deck
	def move_joker_b
		# find the index of the 'b' joker
		index_b = @deck_of_cards.index(Card.new(:joker, 2))
		# if the 'b' joker is the last card in the deck, move it below the first card
		if index_b == 53
			joker_b = @deck_of_cards.delete_at(index_b)
			@deck_of_cards.insert(2, joker_b)

			# new position of the 'b' joker
			new_b = 2
		elsif index_b == 52
			# if the 'b' joker is the second to last in the deck, move it below the first card
			joker_b = @deck_of_cards.delete_at(index_b)
			@deck_of_cards.insert(1, joker_b)

			# new position of the 'b' joker
			new_b = 1
		else # move the 'b' joker down two cards
			@deck_of_cards[index_b], @deck_of_cards[index_b + 1] = @deck_of_cards[index_b + 1], @deck_of_cards[index_b] 
			@deck_of_cards[index_b + 1], @deck_of_cards[index_b + 2] = @deck_of_cards[index_b + 2], @deck_of_cards[index_b + 1]
			
			#new positon of the 'b' joker
			new_b = index_b + 2
		end
	end

	## performs a triple split on the deck using the positions of the top and bottom joker
	# cards as the pivot points
	def triple_split(top_joker, bottom_joker)
		# everything above the top joker moves below the bottom joker
		# and everything below the bottom joker moves to above the top
		# joker
		top_cards 	 = @deck_of_cards[0...top_joker]
		mid_cards		 = @deck_of_cards[top_joker..bottom_joker]
		bottom_cards = @deck_of_cards[bottom_joker+1..53]
		@deck_of_cards.clear
		@deck_of_cards += (bottom_cards)+(mid_cards)+(top_cards)
	end

	## performs a cut operation on the deck using the value of the card on the 
	# bottom of the deck
	def count_cut(value)
		# cuts 'value' cards from the top of the deck and inserts them
		# right before the last element
		value.times do
			card = @deck_of_cards.delete_at(0)
			@deck_of_cards.insert(-2, card)
		end
	end
end

class Message
	attr_reader :string, :length

	## creates a message object. we do not want any other characters aside from letters present in the message
	# object. we also want to pad the string with an amount of X's so the length is a multiple of 5.
	def initialize(message)
		@string = message.gsub(/[^a-zA-Z]/, '').upcase
		@length = @string.size()

		if @length < 5
			@string += "X" * (5 - @length)
			@length = 5
		elsif @length % 5 != 0
			@string += "X" * (5 - (@length % 5))
			@length += (5 - (@length % 5))
		end

	end

	## to-string method that displays the string in groupings of 5
	def display
		r_str = "Message: "
		(@length / 5).times { |i| r_str += "#{@string[(i * 5)...(i * 5) + 5]} " }
		puts r_str
	end

	## returns an encrypted stream of letters from a keystream object using this message
	# object's string
	def encrypt(keystream)
		encrypted_stream = String.new
		@length.times do |i|
			a = if keystream[i] % 26 == 0
				26
			else
				keystream[i] % 26
			end
			b = string[i].ord - 64
			encrypted_stream << if a + b > 26
				((a + b - 26) + 64).chr
			else
				((a + b) + 64).chr
			end
		end
		encrypted_stream
	end

	## returns a decrypted stream of letters from a keystream object using this
	# message object's string
	def decrypt(keystream)
		decrypted_stream = String.new
		@length.times do |i|
			a = if keystream[i] % 26 == 0
				26
			else
				keystream[i] % 26
			end
			b = string[i].ord - 64
			decrypted_stream << if b - a <= 0
				((b - a + 26) + 64).chr
			else
				((b - a) + 64).chr
			end
		end
		decrypted_stream
	end
end







