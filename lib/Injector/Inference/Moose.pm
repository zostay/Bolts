package Injector::Inference::Moose;
use Moose;

with 'Injector::Inference';

use Moose::Util ();

sub infer {
    my ($self, $bag) = @_;
    my @parameters;

    my $meta = Moose::Util::find_meta($bag);
    if (defined $meta and not Moose::Util::is_rol($bag)) {
        ATTR: for my $attr ($meta->get_all_attributes) {
            my $key;
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
                isa        => $attr->isa,
                does       => $attr->does,
                optional   => !$attr->required,
            };
        }
    }

    return @parameters;
}

__PACKAGE__->meta->make_immutable;
