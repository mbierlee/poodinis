import poodinis;

interface Database{};
class RelationalDatabase : Database {}

class DataWriter {
	@Autowire
	public Database database; // Automatically injected when class is resolved
}

void main() {
	auto dependencies = DependencyContainer.getInstance();
	dependencies.register!DataWriter;
	dependencies.register!(Database, RelationalDatabase);

	auto writer = dependencies.resolve!DataWriter;
}
