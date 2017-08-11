# Metal Command-Line

A sample command-line app for Metal compute shaders (written in Swift).


## Compile and Usage

1. Clone the project

	```bash
	git clone https://github.com/dehesa/Metal-CLI.git
	```

2. Build the project

	```bash
	cd Metal-CLI
	xcodebuild -project Metal-CLI.xcodeproj
	```

3. Execute the Command-Line app

	```bash
	cd build/Release
	./MetalCLI /absolute/path/to/image.jpg
	```
