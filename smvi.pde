import java.util.Random;

final int MARGIN = 6;
final int SPACE_COLOR = 0;
final int MAX_COLOR_VAL = 255;
final String IMAGE_PATH = "image.jpg";
final int FUZZING_STEP = 3000;

final float TOLERANCE = 0.6;
final float THRESHOLD = 0.75;

Grid grid;
Manipulator manipulator;

void setup() {
  size(512, 512);
  grid = new Grid(MARGIN, new Color(SPACE_COLOR));
  grid.loadImage_(IMAGE_PATH);
  manipulator = new Manipulator(grid);
}

void draw() {
  manipulator.update();
  grid.draw();
}

void mouseClicked() {
  manipulator.changeState();
}

class Color {
  int red;
  int green;
  int blue;
  
  Color(int initialVal) {
    red = green = blue = initialVal;
  }
  
  Color(int initialRed, int initialGreen, int initialBlue) {
    red = initialRed;
    green = initialGreen;
    blue = initialBlue;
  }
  
  Color copy() {
    return new Color(red, green, blue);
  }
}

enum CellType { AGENT, SPACE };

class Cell {
  Color color_;
  CellType type;
  
  Cell(final Color initialColor) {
    color_ = initialColor.copy();
    if (color_.red   >= (SPACE_COLOR - TOLERANCE*MAX_COLOR_VAL) && color_.red   <= (SPACE_COLOR + TOLERANCE*MAX_COLOR_VAL) &&
        color_.green >= (SPACE_COLOR - TOLERANCE*MAX_COLOR_VAL) && color_.green <= (SPACE_COLOR + TOLERANCE*MAX_COLOR_VAL) &&
        color_.blue  >= (SPACE_COLOR - TOLERANCE*MAX_COLOR_VAL) && color_.blue  <= (SPACE_COLOR + TOLERANCE*MAX_COLOR_VAL)) {
      type = CellType.SPACE;
    } else {
      type = CellType.AGENT;
    }
  }
}

class Grid {
  int margin;
  Color spaceColor;
  Cell[] cells;
  
  Grid(int initialMargin, final Color initialSpaceColor) {
    cells = new Cell[width*height];
    margin = initialMargin;
    spaceColor = initialSpaceColor.copy();
    
    for (int i = 0; i < cells.length; ++i) {
      cells[i] = new Cell(initialSpaceColor);
    }
  }
  
  void loadImage_(final String path) {
    PImage img = loadImage(path);
    
    for (int row = 0; row < height - 2*margin; ++row) {
      for (int col = 0; col < width - 2*margin; ++col) {
        int cell_idx = width*(row + margin) + (col + margin);
        color c = img.get(col, row);
        cells[cell_idx] = new Cell(new Color(int(red(c)), int(green(c)), int(blue(c))));
      }
    }
  }
  
  void draw() {
    loadPixels();
    for (int i = 0; i < cells.length; ++i) {
      pixels[i] = color(cells[i].color_.red, cells[i].color_.green, cells[i].color_.blue);
    }
    updatePixels();
  }
  
  void swapCells(int index1, int index2) {
    Cell tmpCell = cells[index1];
    cells[index1] = cells[index2];
    cells[index2] = tmpCell;
  }
  
  int[] getCellNeighbourIndex(int index) {
    int left = getCellLeftNeighbourIndex(index);
    int top = getCellTopNeighbourIndex(index);
    int right = getCellRightNeighbourIndex(index);
    int bottom = getCellBottomNeighbourIndex(index);

    int topLeft = getCellLeftNeighbourIndex(top);
    int topRight = getCellRightNeighbourIndex(top);
    int bottomLeft = getCellLeftNeighbourIndex(bottom);
    int bottomRight = getCellRightNeighbourIndex(bottom);

    return new int[] { left, topLeft, top, topRight, right, bottomRight, bottom, bottomLeft };
  }
  
  int getCellLeftNeighbourIndex(int index) {
    if (index % width == 0) {
      return index + width - 1;
    } else {
      return index - 1;
    }
  }

  int getCellRightNeighbourIndex(int index) {
    if ((index + 1) % width == 0) {
      return index - width + 1;
    } else {
      return index + 1;
    }
  }

  int getCellTopNeighbourIndex(int index) {
    if (index < width) {
      return width*height - (width - index);
    } else {
      return index - width;
    }
  }

  int getCellBottomNeighbourIndex(int index) {
    if (index >= width*(height - 1)) {
      return index - width*(height - 1);
    } else {
      return index + width;
    }
  }
}

class State {
  Grid grid;
  int step;
  int pos = 0;
  
  State(Grid initialGrid, int initialStep) {
    grid = initialGrid;
    step = initialStep;
  }
  
  void update() {
  }
}

class Fuzzing extends State {
  Fuzzing(Grid initialGrid, int initialStep) {
    super(initialGrid, initialStep);
  }
  
  void update() {
    Random rand = new Random();
    for (int i = 0; i < step; ++i) {
      int index1 = rand.nextInt(grid.cells.length);
      int index2 = rand.nextInt(grid.cells.length);
      grid.swapCells(index1, index2);
    }
  }
}

class Segregation extends State {
  float threshold;
  float tolerance;
  IntList spaceCellsIndexes;
  
  Segregation(Grid initialGrid, int initialStep, float initialThreshold, float initialTolerance) {
    super(initialGrid, initialStep);
    threshold = initialThreshold;
    tolerance = initialTolerance;
    spaceCellsIndexes = new IntList();
    
    for (int i = 0; i < grid.cells.length; ++i) {
      if (grid.cells[i].type == CellType.SPACE) {
        spaceCellsIndexes.append(i);
      }
    }
  }
  
  boolean areColorsSimilar(final Color color1, final Color color2) {
    int[] diffs = {
      abs(color1.red - color2.red),
      abs(color1.green - color2.green),
      abs(color1.blue - color2.blue)
    };
    
    for (int i = 0; i < diffs.length; ++i) {
      if (diffs[i] >= TOLERANCE*MAX_COLOR_VAL) {
        return false;
      }
    }
    
    return true;
  }
  
  boolean isCellSatisfied(int index) {
    if (grid.cells[index].type == CellType.SPACE) {
      return true;
    }
    
    int numOfNeighboursHavingSimilarColor = 0;
    int[] neighbourIndexes = grid.getCellNeighbourIndex(index);
    for (int i = 0; i < neighbourIndexes.length; ++i) {
      if (areColorsSimilar(grid.cells[index].color_, grid.cells[neighbourIndexes[i]].color_)) {
        ++numOfNeighboursHavingSimilarColor;
      }
    }
    
    return (float(numOfNeighboursHavingSimilarColor) / float(neighbourIndexes.length)) >= threshold;
  }
  
  void update() {
    IntList unsatisfiedCellIndexes = new IntList();
    for (int i = 0; i < grid.cells.length; ++i) {
      if (isCellSatisfied(i) == false) {
        unsatisfiedCellIndexes.append(i);
      }
    }
    
    unsatisfiedCellIndexes.shuffle();
    
    Random rand = new Random();
    for (int i = 0; i < unsatisfiedCellIndexes.size(); ++i) {
      int unsatisfiedIndex = unsatisfiedCellIndexes.get(i);
      int spaceIndex = rand.nextInt(spaceCellsIndexes.size());
      
      grid.swapCells(spaceCellsIndexes.get(spaceIndex), unsatisfiedIndex);
      spaceCellsIndexes.set(spaceIndex, unsatisfiedIndex);
    }
  }
}

class Manipulator {
  Grid grid;
  State state;
  
  Manipulator(Grid initialGrid) {
    grid = initialGrid;
    state = new State(grid, 0);
  }
  
  void update() {
    state.update();
  }
  
  void changeState() {
    if (state.getClass() == State.class || state.getClass() == Segregation.class) {
      state = new Fuzzing(grid, FUZZING_STEP);
    } else if (state.getClass() == Fuzzing.class) {
      state = new Segregation(grid, 0, THRESHOLD, TOLERANCE);
    }
  }
}
