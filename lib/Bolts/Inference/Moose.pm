package Bolts::Inference::Moose;
use Moose;

with 'Bolts::Inference';

use Class::Load ();
use Moose::Util ();

sub infer {
    my ($self, $blueprint) = @_;

    return unless $blueprint->isa('Bolts::Blueprint::Factory');

    my $class = $blueprint->class;
    Class::Load::load_class($class);

    my $meta = Moose::Util::find_meta($class);

    return unless defined $meta;

    my @parameters;
    ATTR: for my $attr ($meta->get_all_attributes) {
        my ($preferred_injector, $key);
        if (defined $attr->init_arg) {
            $preferred_injector = 'parameter_name';
            $key = $attr->init_arg;
        }
        elsif ($attr->has_write_method) {
            $preferred_injector = 'setter';
            $key = $attr->get_write_method;
        }
        else {
            next ATTR;
        }

        push @parameters, {
            key        => $key,
            inject_via => $preferred_injector,
            isa        => $attr->type_constraint,
            required   => $attr->is_required,
        };
    }

    return @parameters;
}

__PACKAGE__->meta->make_immutable;
