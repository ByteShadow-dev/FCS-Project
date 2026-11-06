# Project Report — Tensor / Machine Learning Library + Jack Games

## 1. What our project is

We built a small **tensor (matrix) and machine-learning library** for the
nand2tetris **Hack** computer, written in the **Jack** language. We also built an
interactive text workbench, a benchmark, and two playable games on top of it.

The Hack computer only understands **16-bit signed integers** — there are no
decimal or floating-point numbers. So every calculation in the project is done
with **fixed-point math** (for example, values stored as "×1000" to keep the
extra precision).

### Main parts of the project

- **Tensor library** — `Tensor.jack` stores a 2-D grid of numbers in one flat,
  row-by-row array. `TensorOps.jack` does the actual work: add, subtract,
  multiply by a number, divide by a number, matrix multiply, and transpose.
  Each operation has a simple version (`V0`) and a faster version (`V2`) that
  uses loop unrolling.
- **Machine-learning models** — three simple models that learn from data:
  - `LinearRegression` — fits a straight line, `y = mx + b`.
  - `LogisticRegression` — binary classification (yes/no) using a simple
    piecewise sigmoid.
  - `PolynomialRegression` — fits a curve, `y = w2·x² + w1·x + b`.
- **3×3 matrix toolkit** — `Matrix3x3.jack` adds, subtracts, multiplies,
  transposes, finds the trace, determinant, inverse, and searches for integer
  eigenvalues.
- **Interactive workbench** — `Main.jack` is a text menu where a user can train
  a linear regression or try matrix operations.
- **Benchmark** — `TensorBench.jack` compares the simple (`V0`) and optimised
  (`V2`) tensor operations.
- **Two games**:
  - **Cannon** — a turn-based cannon game whose aiming model *learns* the
    relationship between shot power and where the shot lands.
  - **TicTacToe** — a two-player 3×3 game that treats the board as a matrix and
    uses matrix operations to detect wins.
- **Build script** — `tools/build.ps1` combines the shared library with a chosen
  app and compiles everything into a ready-to-run folder.

---

## 2. Team members and their contributions

| Member | Main area | Main files |
|--------|-----------|------------|
| **Shubham Kumar Behera** (ByteShadow-dev) | Project setup, core tensor library, benchmark, regression fixes | `src/Tensor.jack`, `src/TensorOps.jack`, `bench/TensorBench.jack`, `src/LinearRegression.jack` |
| **Sriram** (cnSriram) | 3×3 matrix operations, extra models, workbench menu | `src/Matrix3x3.jack`, `src/LogisticRegression.jack`, `src/PolynomialRegression.jack`, `src/Main.jack` |
| **Saniya** | TicTacToe game | `apps/TicTacToe/Board.jack`, `apps/TicTacToe/Game.jack`, `apps/TicTacToe/Main.jack` |
| **Riya Murarka** | Build system, documentation, Cannon game, integration | `tools/build.ps1`, `README.md`, `apps/Cannon/*` |

### Shubham Kumar Behera — foundation and core library

- Started the repository and made the **initial commit**.
- Built the **core tensor library**: how a tensor is stored, how to create,
  access, fill, compare, and print it.
- Wrote the **tensor operations** (add, subtract, scalar multiply/divide,
  matrix multiply, transpose) in both simple and optimised forms.
- Wrote the **benchmark harness** and the first versions of the linear
  regression model and demo.
- Set up the project's `.gitignore`.
- Later went back and **fixed integer overflow problems** and made major
  improvements to `LinearRegression`, including safer arithmetic and input
  normalisation. Also updated the logistic model and the workbench.
- Reviewed and **merged Sriram's matrix and menu work** into the main branch.

### Sriram — matrix toolkit and interaction

- Added the complete **3×3 matrix toolkit**: add, subtract, multiply,
  transpose, trace, determinant, inverse, and an integer eigenvalue search.
- Added the **LogisticRegression** and **PolynomialRegression** models.
- Built the **interactive menu/workbench** (`Main.jack`) that lets a user run
  linear regression and matrix operations without writing code.
- Added a VM test script (`RunDemo.tst`).

### Saniya — TicTacToe game

- Designed and wrote the **TicTacToe game** (`Board.jack`, `Game.jack`,
  `Main.jack`).
- The board is stored as a **3×3 Tensor**. Wins are detected using the matrix
  library: `Matrix3x3.multiply` computes row and column sums, and
  `Matrix3x3.trace` checks the two diagonals.
- The game has two players, arrow-key movement, a highlighted winning line,
  alternating starting player, and a running match score.
- *(The game was added to the repository by Riya in the commit named
  "saniya's tictactoe game".)*

### Riya Murarka — build, docs, Cannon game, integration

- Wrote the **build script** (`tools/build.ps1`). It finds the Jack compiler,
  copies the shared library plus the chosen app into a build folder, adds the
  `Sys.vm` bootstrap, and compiles everything.
- Wrote the **README** documentation explaining how to build, run, and use the
  library.
- Built the **Cannon game** (`Main.jack`, `Game.jack`, `Projectile.jack`,
  `AimModel.jack`). `AimModel` connects the game to the library's
  `LinearRegression`, so the cannon improves its aim after each shot.
- Integrated and committed the **TicTacToe game**, made final fixes, and pushed
  the finished project.

---

## 3. How the pieces fit together

The **library** (`src/`) is shared by everything. Each app is compiled together
with the library into one output folder:

- `Tensor` → the basic data container.
- `TensorOps` → fast/slow maths on tensors.
- `LinearRegression`, `LogisticRegression`, `PolynomialRegression` → learning
  models built on tensors.
- `Matrix3x3` → matrix-specific helpers built on tensors.
- `Main` → the text workbench.
- `apps/Cannon` → uses `LinearRegression` to aim.
- `apps/TicTacToe` → uses `Tensor` and `Matrix3x3` for the board.

This shows a full small software stack: **data structure → operations →
learning models → applications**.

---

## 4. Quick summary

| Person | One-line contribution |
|--------|-----------------------|
| **Shubham Kumar Behera** | Started the project, built the tensor core and benchmark, and fixed the regression maths. |
| **Sriram** | Added the 3×3 matrix toolkit, extra regression models, and the interactive menu. |
| **Saniya** | Designed and wrote the TicTacToe game using the matrix library. |
| **Riya Murarka** | Built the build system and docs, created the Cannon game, and integrated everything. |

*Note: early experimental work (Pong AI and a tensor-reshape extension) was kept
in backup commits and is not part of the final project.*
