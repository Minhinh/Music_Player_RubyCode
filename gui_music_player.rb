require 'rubygems'
require 'gosu'

TOP_COLOR = Gosu::Color::GREEN
BOTTOM_COLOR = Gosu::Color::BLUE
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
# Display track's name
X_LOCATION = 500

module ZOrder
	BACKGROUND, PLAYER, UI = *0..2
end

module Genre
	POP, CLASSIC, JAZZ, ROCK = *1..4
end

GENRE_NAMES = ['Null', 'Pop', 'Classic', 'Jazz', 'Rock']

class Playlists
	attr_accessor :img, :dim

	def initialize(file, leftX, topY)
		@img = Gosu::Image.new(file)
		@dim = Dimension.new(leftX, topY, leftX + @img.width(), topY + @img.height())
	end
end

class Album
	attr_accessor :title, :artist, :playlists, :tracks

	def initialize (title, artist, playlists, tracks)
		@title = title
		@artist = artist
		@playlists = playlists
		@tracks = tracks
	end
end

class Track
	attr_accessor :name, :location, :dim

	def initialize(name, location, dim)
		@name = name
		@location = location
		@dim = dim
	end
end

class Dimension 
	attr_accessor :leftX, :topY, :rightX, :bottomY

	def initialize(leftX, topY, rightX, bottomY)
		@leftX = leftX
		@topY = topY
		@rightX = rightX
		@bottomY = bottomY
	end
end

class MusicPlayerMain < Gosu::Window

	def initialize
		super SCREEN_WIDTH, SCREEN_HEIGHT
		self.caption = "GUIMusicPlayer"
		@track_font = Gosu::Font.new(25)
		@albums = read_albums()
		@album_playing = -1
		@track_playing = -1
	end

	# Read a single track
	def read_track(a_file, idx)
		track_name = a_file.gets.chomp
		track_location = a_file.gets.chomp
		# Allocate the dimension of the track's title
		leftX = X_LOCATION
		#gap between playlists
		topY = 50 * idx	 + 30
		rightX = leftX + @track_font.text_width(track_name)
		bottomY = topY + @track_font.height()
		dim = Dimension.new(leftX, topY, rightX, bottomY)
		# Create a track object 
		track = Track.new(track_name, track_location, dim)
		return track
	end

	# Read all tracks of an album
	def read_tracks(a_file)
		count = a_file.gets.chomp.to_i
		tracks = Array.new()
		# Read each track and add it into the array
		i = 0
		while i < count
			track = read_track(a_file, i)
			tracks << track
			i += 1
		end
		return tracks
	end

	# Read a single album
	def read_album(a_file, idx)
		title = a_file.gets.chomp
		artist = a_file.gets.chomp
		# Dimension x of an album's playlists
		if idx % 2 == 0
			leftX = 30
		else
			leftX = 250
		end

		topY = 190 * (idx / 2) + 30 * (idx / 2)
		playlists = Playlists.new(a_file.gets.chomp, leftX, topY)
		tracks = read_tracks(a_file)
		album = Album.new(title, artist, playlists, tracks)

		return album
	end

	# Read all albums
	def read_albums()
		a_file = File.new("input.txt", "r")
		count = a_file.gets.chomp.to_i
		albums = Array.new()

		i = 0
		while i < count
			album = read_album(a_file, i)
			albums << album
			i += 1
		end

		a_file.close()
		return albums
	end

	# Draw albums' aplaylists
	def draw_albums(albums)
		albums.each do |album|
			album.playlists.img.draw(album.playlists.dim.leftX, album.playlists.dim.topY, z = ZOrder::PLAYER)
		end
	end

	# Draw tracks' titles of a given album
	def draw_tracks(album)
		album.tracks.each do |track|
			display_track(track)
		end
	end

	# Draw indicator of the current playing song
	def draw_current_playing(idx, album)
		draw_rect(album.tracks[idx].dim.leftX - 10, album.tracks[idx].dim.topY, 5, @track_font.height(), Gosu::Color::RED, z = ZOrder::PLAYER)
	end

	# Detects if a 'mouse sensitive' area has been clicked on
	# Either an album or a track. returns true or false
	def area_clicked(leftX, topY, rightX, bottomY)
		if mouse_x > leftX && mouse_x < rightX && mouse_y > topY && mouse_y < bottomY
			return true
		end
		return false
	end

	# Takes a String title and an Integer Yposition
	def display_track(track)
		@track_font.draw(track.name, X_LOCATION, track.dim.topY, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
	end

	# Takes a track index and an Album and plays the Track from the Album
	def playTrack(track, album)
		@song = Gosu::Song.new(album.tracks[track].location)
		@song.play(false)
	end

	# Draw a coloured background using TOP_COLOR and BOTTOM_COLOR
	def draw_background()
		draw_quad(0, 0, TOP_COLOR, 0, SCREEN_HEIGHT, TOP_COLOR, SCREEN_WIDTH, 0, BOTTOM_COLOR, SCREEN_WIDTH, SCREEN_HEIGHT, BOTTOM_COLOR, z = ZOrder::BACKGROUND)
	end

	# Not used? Everything depends on mouse actions.
	def update
		# If a new album has just been seleted, and no album was selected before -> start the first song of that album
		if @album_playing >= 0 && @song == nil
			@track_playing = 0
			playTrack(0, @albums[@album_playing])
		end

		# If an album has been selecting, play all songs in turn
		if @album_playing >= 0 && @song != nil && (not @song.playing?)
			@track_playing = (@track_playing + 1) % @albums[@album_playing].tracks.length()
			playTrack(@track_playing, @albums[@album_playing])
		end
	end

	# Draws the album images and the track list for the selected album
	def draw
		draw_background()
		draw_albums(@albums)
		# If an album is selected => display its tracks
		if @album_playing >= 0
			draw_tracks(@albums[@album_playing])
			draw_current_playing(@track_playing, @albums[@album_playing])
		end
	end

	def needs_cursor?
		true;
	end

def button_down(id)
	case id
	when Gosu::MsLeft

		# If an album has been selected
		if @album_playing >= 0
			# Check which track was clicked on
			for i in 0..@albums[@album_playing].tracks.length() - 1
				if area_clicked(@albums[@album_playing].tracks[i].dim.leftX, @albums[@album_playing].tracks[i].dim.topY, @albums[@album_playing].tracks[i].dim.rightX, @albums[@album_playing].tracks[i].dim.bottomY)
					playTrack(i, @albums[@album_playing])
					@track_playing = i
					break
				end
			end
		end

		# Check which album was clicked on
		for i in 0..@albums.length() - 1
			if area_clicked(@albums[i].playlists.dim.leftX, @albums[i].playlists.dim.topY, @albums[i].playlists.dim.rightX, @albums[i].playlists.dim.bottomY)
				@album_playing = i
				@song = nil
				break
			end
		end
	end
end

end

# Show is a method that loops through update and draw
MusicPlayerMain.new.show if __FILE__ == $0