from setuptools import setup, Extension
from setuptools import find_packages
import os
import sysconfig
import pybind11

# Get Python and pybind11 include paths programmatically
python_include = sysconfig.get_paths()['include']
pybind11_include = pybind11.get_include()

# Configure compiler flags and include directories
extra_compile_args = ['-std=c++11', '-O3']
include_dirs = [
    python_include,
    pybind11_include
]

# Print paths for debugging
print(f"Python include path: {python_include}")
print(f"Pybind11 include path: {pybind11_include}")

# Configure the C++ extension
ext_modules = [
    Extension(
        "lru_cache",
        ["src/lru_cache.cpp"],
        include_dirs=include_dirs,
        language='c++',
        extra_compile_args=extra_compile_args,
    ),
    Extension(
        "srrip_cache",
        ["src/srrip_cache.cpp"],
        include_dirs=include_dirs,
        language='c++',
        extra_compile_args=extra_compile_args,
    )
]

setup(
    name="EVASim",
    version="0.1",
    packages=find_packages(),
    ext_modules=ext_modules,
    install_requires=[
        'pybind11>=2.6.0',
    ],
    setup_requires=[
        'pybind11>=2.6.0',
    ],
    zip_safe=False,
    python_requires='>=3.6'
)
