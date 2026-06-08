#pragma once
#include <filesystem>
#include <memory>
#include <optional>

#include "IBinaryStream.h"
#include "Core/NoCopyMove.hpp"

namespace wallpaper
{
namespace fs
{

class Fs : NoCopy,NoMove {
public:
	virtual bool Contains(std::string_view path) const = 0;
	virtual std::shared_ptr<IBinaryStream> Open(std::string_view path) = 0;
	virtual std::shared_ptr<IBinaryStreamW> OpenW(std::string_view path) = 0;
    virtual std::optional<std::filesystem::path> ResolvePhysicalPath(std::string_view) const {
        return std::nullopt;
    }
public:
	Fs() = default;
	virtual ~Fs() = default;
};

}
}
