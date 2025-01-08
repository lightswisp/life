require 'gosu'

WIDTH = 800
HEIGHT = 800
CELL_SIZE = 20

Cell = Struct.new(
  :x,
  :y,
  :alive
)

module Natural
  def number(n)
    n.negative? ? nil : n
  end
end

include Natural

class Game < Gosu::Window
  def initialize(width, height, cell_size, margin = 1, timeout = 0.1)
    super width, height
    self.caption           = 'game of life'
    @cell_size             = cell_size
    @margin                = margin
    @timeout               = timeout
    @cols                  = (self.width / (@cell_size + @margin).to_f).floor
    @rows                  = (self.height / (@cell_size + @margin).to_f).floor
    @current_generation    = 0
    @generations           = []
    @generations[@current_generation] = init_cells
    @ms_left_clicked       = false
    @ms_right_clicked      = false
    @is_space_pressed      = false
    @is_simulation_running = false
  end

  def init_cells
    cells = []
    @rows.times do |y|
      cells << []
      @cols.times do |x|
        cells[y][x] = Cell.new(
          (@cell_size * x) + ((x + 1) * @margin),
          (@cell_size * y) + ((y + 1) * @margin),
          false
        )
      end
    end
    cells
  end

  def find_nearest_cell(x, y)
    n_y = (y / (@cell_size + @margin).to_f).floor
    n_x = (x / (@cell_size + @margin).to_f).floor
    [n_y, n_x]
  end

  def lmouse_clicked?
    if button_down?(Gosu::MsLeft)
      @ms_left_clicked = true
    elsif @ms_left_clicked
      @ms_left_clicked = false
      return true
    end
    false
  end

  def rmouse_clicked?
    if button_down?(Gosu::MsRight)
      @ms_right_clicked = true
    elsif @ms_right_clicked
      @ms_right_clicked = false
      return true
    end
    false
  end

  def space_pressed?
    if button_down?(Gosu::KB_SPACE)
      @is_space_pressed = true
    elsif @is_space_pressed
      @is_space_pressed = false
      return true
    end
    false
  end

  def get_neighbours(x, y)
    # returns all 8 alive neighbours (explained in moore neighbourhood)
    cells = @generations[@current_generation]

    nw_y = Natural.number(y - 1)
    nw_x = Natural.number(x - 1)
    nw   = cells[nw_y][nw_x] if nw_y && nw_x

    n_y  = Natural.number(y - 1)
    n_x  = x
    n    = cells[n_y][n_x] if n_y && n_x

    ne_y = Natural.number(y - 1)
    ne_x = x + 1
    ne = cells[ne_y][ne_x] if ne_y && ne_x

    w_y = y
    w_x = Natural.number(x - 1)
    w = cells[w_y]&.at(w_x) if w_y && w_x

    e_y = y
    e_x = x + 1
    e = cells[e_y][e_x] if e_y && e_x

    sw_y = y + 1
    sw_x = Natural.number(x - 1)
    sw = cells[sw_y]&.at(sw_x) if sw_y && sw_x

    s_y = y + 1
    s_x = x
    s = cells[s_y]&.at(s_x) if s_y && s_x

    se_y = y + 1
    se_x = x + 1
    se = cells[se_y]&.at(se_x) if se_y && se_x

    [nw, n, ne, w, e, sw, s, se].reject { |n| n.nil? }
  end

  def init_next_generation
    # because .clone on structs still mutates the original ones

    current_generation = @generations[@current_generation]
    @generations[@current_generation + 1] = []

    @rows.times do |y|
      @generations[@current_generation + 1] << []
      @cols.times do |x|
        @generations[@current_generation + 1][y][x] = Cell.new(current_generation[y][x].x,
                                                               current_generation[y][x].y,
                                                               current_generation[y][x].alive)
      end
    end
  end

  def simulate
    # initialize the next generation
    current_generation = @generations[@current_generation]
    init_next_generation

    @rows.times do |y|
      @cols.times do |x|
        current_cell = current_generation[y][x]

        # neighbour check
        neighbours = get_neighbours(x, y)
        alive_neighbours = neighbours.count { |neighbour| neighbour.alive }
        if current_cell.alive
          if alive_neighbours < 2
            # it dies because of underpopulation
            @generations[@current_generation + 1][y][x].alive = false
          elsif [2, 3].include?(alive_neighbours)
            # it lives on to the next generation
            @generations[@current_generation + 1][y][x].alive = true
          elsif alive_neighbours > 3
            # dies because of overpopulation
            @generations[@current_generation + 1][y][x].alive = false
          end
        elsif alive_neighbours == 3
          @generations[@current_generation + 1][y][x].alive = true
          # any dead cell with exactly three live neighbours becomes a live cell (by reproduction)
        end
      end
    end

    # move next
    @current_generation += 1
  end

  def update
    if space_pressed?
      # run/stop the simulation
      @is_simulation_running = !@is_simulation_running
      puts @is_simulation_running
    end

    if @is_simulation_running
      simulate
      sleep @timeout
    end

    if lmouse_clicked?
      puts "clicked at (#{mouse_x}, #{mouse_y})"
      n_y, n_x = find_nearest_cell(mouse_x, mouse_y)
      nearest_cell = @generations[@current_generation][n_y]&.at(n_x)
      nearest_cell&.alive = true
    elsif rmouse_clicked?
      n_y, n_x = find_nearest_cell(mouse_x, mouse_y)
      nearest_cell = @generations[@current_generation][n_y]&.at(n_x)
      nearest_cell&.alive = false
    end
  end

  def draw
    @rows.times do |y|
      @cols.times do |x|
        cells = @generations[@current_generation]
        cell = cells[y][x]
        if cell.alive
          draw_rect(cell.x, cell.y, @cell_size, @cell_size, Gosu::Color.argb(0xff_ffffff))
        else
          draw_rect(cell.x, cell.y, @cell_size, @cell_size, Gosu::Color.argb(0xff_555555))
        end
      end
    end
  end
end

Game.new(WIDTH,
         HEIGHT,
         CELL_SIZE).show
