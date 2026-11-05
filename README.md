# CS207 Tensor / ML Library + Jack Games

A nand2tetris **Jack** project containing:

- a row-major 2-D integer tensor library with naive (`V0`) and optimised (`V2`) kernels;
- linear, logistic, and quadratic regression models;
- 3x3 matrix operations, including inverse and integer eigenvalue search;
- an interactive text workbench;
- a tensor benchmark harness;
- two screen games: **Cannon** and **TicTacToe**.

Everything runs on the Hack platform in 16-bit signed integer arithmetic. There
are no floating-point numbers.

## The four game paths

| # | Path | What it is |
|---|------|------------|
| 1 | `apps/Cannon/` | Cannon source: `Main.jack`, `Game.jack`, `AimModel.jack`, `Projectile.jack` |
| 2 | `build/Cannon/` | Compiled Cannon `.vm` files (load this folder in the VM Emulator) |
| 3 | `apps/TicTacToe/` | TicTacToe source: `Main.jack`, `Game.jack`, `Board.jack` |
| 4 | `build/TicTacToe/` | Compiled TicTacToe `.vm` files (load this folder in the VM Emulator) |

`build/` is generated and ignored by git. Recreate it with `tools/build.ps1`.

## Requirements

- The nand2tetris toolchain: `JackCompiler` and `VMEmulator`.
- PowerShell 5.1 or newer (for `tools/build.ps1`).
- A folder containing the nand2tetris tools. The build script looks in common
  relative locations, or you can pass the compiler path explicitly.

Jack has no packages: an application is compiled together with the library
into one output folder.

## Quick build

From the repository root:

```powershell
# Interactive text workbench (src/Main.jack)
.\tools\build.ps1 -App src

# Cannon game
.\tools\build.ps1 -App apps/Cannon

# TicTacToe game
.\tools\build.ps1 -App apps/TicTacToe
```

Output folders:

| Build | Output |
|-------|--------|
| `-App src` | `build/demo/` |
| `-App apps/Cannon` | `build/Cannon/` |
| `-App apps/TicTacToe` | `build/TicTacToe/` |

If `JackCompiler` is not found:

```powershell
.\tools\build.ps1 -App apps/Cannon -JackCompiler "C:\path\to\nand2tetris\tools\JackCompiler.bat"
```

You can also set `NAND2TETRIS_HOME` to the nand2tetris root. Add `-Run` to try
to launch `VMEmulator.bat` after a successful build.

## Running in the VM Emulator

1. Start `VMEmulator.bat`.
2. Click **Load Program** and select the **folder** containing the `.vm` files
   (for example `build/Cannon`), not an individual `.vm` file.
3. Click the emulated screen once to focus it.
4. Set the speed to **Fast**, then click **Run**.

The build script also copies the nand2tetris `OS/*.vm` files into the output
folder, so `Sys.init` is always present even if the emulator's built-in OS is
unavailable.

The emulator runs `Main.main` from the loaded folder. Application builds exclude
`src/Main.jack` so that the app's `Main` is the only entry point.

## Repository layout

```text
src/                         library + workbench
  Tensor.jack                row-major 2-D integer tensor
  TensorOps.jack             element-wise, scalar, matmul, transpose kernels
  LinearRegression.jack      y = m*x + b
  LogisticRegression.jack    binary classification with a piecewise sigmoid
  PolynomialRegression.jack  quadratic y = w2*x^2 + w1*x + b
  Matrix3x3.jack             3x3 add/sub/mul, trace, transpose, det, inverse
  Main.jack                  interactive workbench menu
  LinearRegressionDemo.jack  standalone regression demo
  RunDemo.tst                VM Emulator test script
  *.vm                       compiled library artifacts

bench/
  TensorBench.jack           V0 vs V2 benchmark harness

apps/
  Cannon/                    learned-aim cannon game
  TicTacToe/                 two-player 3x3 matrix tic-tac-toe

tools/
  build.ps1                  stages src + app and runs JackCompiler

build/                       generated .vm output (ignored by git)
```

## Workbench (`src/Main.jack`)

The default workbench is a text menu:

- **[1] Linear Regression** — enter 2 to 10 points, train for 100 steps with
  learning rate 25, and print the fitted equation plus actual/predicted values.
- **[2] Matrix Operations (3x3)** — add, subtract, multiply, transpose,
  inverse, or trace + integer eigenvalues. Matrix input is prompted
  element-by-element; the prompt describes the values as `x1000`.
- **[Q] Quit**.

`LinearRegressionDemo.jack` is a separate demo class (its `run()` method is not
called by the workbench). It trains on a scaled data set and prints predictions.
To run it, wire it into a `Main` or call it from your own entry point.

`src/RunDemo.tst` is a VM Emulator script that loads the current folder and
steps the VM. It is intended for GUI use; the VM Emulator's command-line
`load .` handling is unreliable, so load the program folder in the GUI instead.

`bench/TensorBench.jack` has no `Main` of its own. Call `TensorBench.runAll()`
from a custom `Main` if you want to run the benchmarks. Its cycle counter is a
placeholder; use the CPU Emulator's cycle display for real measurements.

## Library reference

### `Tensor`

A 2-D tensor stored in a flat, row-major `Array`.

| Method | Purpose |
|--------|---------|
| `new(r, c)` | Allocate an `r * c` tensor, initialised to zero |
| `dispose()` | Free the data array and the object |
| `getRows()`, `getCols()`, `getSize()` | Shape accessors |
| `get(i)`, `set(i, v)` | Flat-index access |
| `at(r, c)`, `put(r, c, v)` | Row/column access |
| `fill(v)` | Set every element to `v` |
| `getData()` | Return the backing `Array` |
| `equals(other)` | Element-wise equality with matching shape |
| `print()`, `printHead(n)` | Print to the Hack output screen |

### `TensorOps`

Each operation has a naive `V0` version and an optimised `V2` version. `V2`
uses direct `Array` access and 4-element loop unrolling. The caller always
allocates the output tensor; operations never allocate.

| Family | Methods |
|--------|---------|
| Add | `addV0`, `addV2` |
| Subtract | `subV0`, `subV2` |
| Scalar multiply | `mulScalarV0`, `mulScalarV2` |
| Scalar divide | `divScalarV0`, `divScalarV2` |
| Matrix multiply | `matmulV0`, `matmulV2` |
| Transpose | `transposeV0`, `transposeV2` |

### `LinearRegression`

`new(capacity, initM, initB, learningRate)` creates a model with storage for
`capacity` points.

- `addPoint(x, y)` — stores a point. **Automatic normalisation:** if `x >= 100`
  it divides `x` by 1000; if `y < 100` it multiplies `y` by 1000. Keep inputs
  in a range that matches the intended fixed-point convention.
- `clearPoints()` — forget stored points (model parameters remain).
- `predictOne(x)` — evaluate the line. `x >= 100` is divided by 1000 first.
- `step()` — one gradient-descent update; returns 0 when `n < 2`.
- `train(maxIter, printEvery)` — run `maxIter` steps; `printEvery > 0` prints
  progress every N steps.
- `computeMSE()`, `computePredictions()` — diagnostics/training helpers.
- `getX(i)`, `getY(i)` — stored point accessors.
- `getM()`, `getB()`, `getSlope()`, `getIntercept()`, `getLR()`,
  `getIteration()`, `getN()` — accessors.
- `setLR(newLR)`, `print()` — configuration/printing.
- `dispose()` — free tensors and the object.

The class is fixed-point by convention rather than enforcing a scale. The
workbench and demo use `x1000` data; the Cannon game deliberately uses small
unscaled integers with `lr = 5`.

### `LogisticRegression`

Binary classification with a piecewise linear sigmoid.

- `new(capacity, initW, initB, learningRate)`.
- `addPoint(x, y)` — expected to receive scaled inputs (`x` around `x1000`,
  `y` as `0` or `1000`).
- `predictOne(x)` — returns a probability in `[0, 1000]`.
- `step()` — one gradient-descent update; returns 0 when `n < 2`.
- `getW()`, `getM()`, `getB()` — accessors.
- `dispose()`.

There is no `train()` helper; call `step()` repeatedly.

### `PolynomialRegression`

Quadratic fitting: `y = w2*x^2 + w1*x + b`.

- `new(capacity, initW2, initW1, initB, learningRate)`.
- `addPoint(x, y)`.
- `predictOne(x)` — computes `x^2` with nested integer divisions to avoid
  overflow.
- `step()` — one update; returns 0 when `n < 2`.
- `getW2()`, `getW1()`, `getB()`.
- `dispose()`.

There is no `train()` helper; call `step()` repeatedly. The `x^2` normalisation
is only suitable for small, specially scaled inputs; it is not used by the
games. For screen-scale coordinates, use `LinearRegression` instead.

### `Matrix3x3`

All methods operate on 3x3 `Tensor` objects.

| Method | Purpose |
|--------|---------|
| `add(a, b, out)`, `subtract(a, b, out)` | Element-wise arithmetic |
| `multiply(a, b, out)` | Standard 3x3 matrix multiplication |
| `transpose(a, out)` | Transpose |
| `trace(a)` | Sum of the main diagonal |
| `det2x2(a,b,c,d)` | 2x2 determinant helper |
| `determinant(a)` | 3x3 determinant by cofactor expansion |
| `invert(a, out)` | Integer adjugate/determinant inverse; returns `false` if singular |
| `evalPoly(x, c2, c1, c0)` | Evaluate the characteristic polynomial |
| `computeEigenvalues(a, evals)` | Search integer eigenvalues in `[-50, 50]` |
| `printMatrix(m)` | Print a clean 3x3 grid |

The inverse uses integer division, so results are approximate. Eigenvalue
search only finds integer roots in the documented range.

## Games

### Cannon

**Path:** `apps/Cannon/` → **build:** `build/Cannon/`

A turn-based cannon game with a learned aiming model.

| Key | Action |
|-----|--------|
| Left / Right | Decrease / increase power (0 to 18) |
| Space | Fire |
| Q | Quit |
| Space after game over | Restart |

How it works:

- The projectile uses simple integer physics: `vx = power`, `vy = -12`, gravity
  `+1`, ground at `y >= 240`.
- `AimModel` wraps the library's `LinearRegression` and learns
  `landingX = m * power + b` from observed shots.
- It stores `y = landingX + 100` so the library's `addPoint` does not rescale
  the target, and trains for 150 steps after at least two points exist.
- The prediction marker under the target appears once the model has two
  observed shots. The HUD shows score, shots, power, prediction, and model
  parameters.
- A hit is within 16 pixels of the target centre; each round has 10 shots.
- Targets are generated deterministically from a seed and move after each shot.

Simulation of the exact integer model and physics gives roughly 8.3 hits out of
10 over random target sequences.

### TicTacToe

**Path:** `apps/TicTacToe/` → **build:** `build/TicTacToe/`

A two-player tic-tac-toe game on a 3x3 matrix board.

| Key | Action |
|-----|--------|
| Arrow keys | Move cursor (wraps around) |
| Space | Place X or O |
| Q | Quit |
| Space after win/draw | Start the next round |

How it works:

- `Board` stores the grid in a 3x3 `Tensor`: `1` = X, `-1` = O, `0` = empty.
- `Matrix3x3.multiply(board, ones, rowSums)` computes row sums.
- `Matrix3x3.multiply(ones, board, colSums)` computes column sums.
- `Matrix3x3.trace(board)` checks the main diagonal.
- `Matrix3x3.trace(board * antiIdentity)` checks the anti-diagonal.
- A line of three X's sums to 3; three O's sums to -3.
- The HUD also shows the board's trace and determinant.
- The winning line is highlighted. The starting player alternates each round,
  and the match score is kept until you quit.

## Numeric and platform notes

- Hack integers are 16-bit signed. Watch for overflow; decompose large products
  where necessary.
- There are no floats. Fixed-point conventions are carried in the code (for
  example, values described as `x1000`).
- Jack evaluates binary operators left-to-right; parenthesise products
  explicitly.
- Add, subtract, matmul, and transpose in `TensorOps` expect compatible shapes;
  the library does not check dimensions.
- `src/*.vm` files are checked-in compiled artifacts. Recompile after editing a
  `.jack` file.
- `build/` is ignored; it is safe to delete and regenerate.

## Troubleshooting

- **`JackCompiler` not found** — pass `-JackCompiler <path>`, set
  `NAND2TETRIS_HOME`, or add the compiler to `PATH`.
- **The VM Emulator shows nothing** — make sure you loaded the output folder
  containing `Main.vm`, then click the screen and press Run.
- **Keyboard does not respond** — click the emulated screen first so it has
  focus. For the games, use the key codes listed above.
- **Duplicate `Main`** — app builds exclude `src/Main.jack`. Do not compile two
  classes named `Main` into the same folder.
- **`gradient`/model behaves strangely** — check the automatic normalisation
  rules in `LinearRegression.addPoint` and `predictOne`, or use the scaling
  conventions shown in `LinearRegressionDemo.jack`.

## Git note

The repository's `.gitignore` currently ignores `README.md`. If you want to
commit this file, use:

```powershell
git add -f README.md
git commit -m "Add project README"
```

Alternatively, remove the `README.md` line from `.gitignore` first.
