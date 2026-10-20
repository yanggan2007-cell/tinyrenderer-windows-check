// a derived shader whose fragment() signature does not match the interface (missing const)
#include <utility>
struct IShader { virtual std::pair<bool, int> fragment(double bar) const = 0; virtual ~IShader() = default; };
struct FlatShader : IShader {
    std::pair<bool, int> fragment(double bar) override { return {false, 0}; }
};
int main() { FlatShader s; return 0; }
